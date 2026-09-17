#!/usr/bin/env node
/**
 * dsh-patch-approval — añade una tercera opción "Always allow" al panel de
 * aprobación del cliente de dsh, con un permiso que dura la sesión activa.
 *
 * El host solo entiende cuatro resultados de aprobación ('allowed-once' |
 * 'rejected' | 'cancelled' | 'unavailable'), así que el "siempre" se implementa
 * entero en el cliente: al pulsar el botón se recuerda el toolName en
 * sessionStorage y, desde ahí, el plugin responde 'allowed-once' sin mostrar el
 * panel para ese tool y esa sesión de agente. Cerrar la pestaña revoca el
 * permiso; el host sigue viendo su vocabulario cerrado intacto.
 *
 * El panel vive en el bundle ya compilado
 *   <install>/node_modules/@deepseek-ai/dsh-client-ui-approval/lib/client.js
 * así que esto es un parche de artefacto: idempotente (marca
 * "dsh:allow-always"), anclado a textos únicos y ruidoso si un cambio upstream
 * rompe un anclaje (nunca deja el archivo a medio parchear). `dsh-update` lo
 * re-aplica después de actualizar el paquete.
 *
 * Uso:
 *   dsh-patch-approval            parchea la instalación activa
 *   dsh-patch-approval --all      parchea todas las instalaciones encontradas
 *   dsh-patch-approval --check    solo informa del estado (no escribe)
 *   dsh-patch-approval --restore  restaura el respaldo <client.js>.dsh-orig
 */

import { execFileSync } from "node:child_process";
import {
	copyFileSync,
	existsSync,
	readFileSync,
	readdirSync,
	realpathSync,
	renameSync,
	statSync,
	unlinkSync,
	writeFileSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import { dirname, join } from "node:path";

/** Marca de idempotencia: su presencia significa "ya parcheado". */
const MARK = "dsh:allow-always";
/** Ruta del bundle, relativa al directorio de scope (@deepseek-ai). */
const CLIENT_REL = join("dsh-client-ui-approval", "lib", "client.js");

// ---------------------------------------------------------------------------
// Texto inyectado
// ---------------------------------------------------------------------------

/** Memoria de permisos por sesión (module scope del plugin). */
const HELPERS = [
	"\t\t//#region dsh:allow-always — permiso de sesión para el panel de aprobación",
	'\t\tconst ALLOW_ALWAYS_PREFIX = "dsh.approval.allowAlways:";',
	"\t\tfunction allowAlwaysRead(sessionId) {",
	"\t\t\ttry {",
	"\t\t\t\tconst raw = window.sessionStorage.getItem(ALLOW_ALWAYS_PREFIX + sessionId);",
	"\t\t\t\tconst parsed = raw === null ? [] : JSON.parse(raw);",
	"\t\t\t\treturn Array.isArray(parsed) ? parsed : [];",
	"\t\t\t} catch {",
	"\t\t\t\treturn [];",
	"\t\t\t}",
	"\t\t}",
	"\t\tfunction allowAlwaysGranted(sessionId, toolName) {",
	"\t\t\treturn allowAlwaysRead(sessionId).includes(toolName);",
	"\t\t}",
	"\t\tfunction allowAlwaysRemember(pending) {",
	"\t\t\ttry {",
	"\t\t\t\tconst granted = allowAlwaysRead(pending.sessionId);",
	"\t\t\t\tif (!granted.includes(pending.toolName)) granted.push(pending.toolName);",
	"\t\t\t\twindow.sessionStorage.setItem(ALLOW_ALWAYS_PREFIX + pending.sessionId, JSON.stringify(granted));",
	"\t\t\t} catch {}",
	"\t\t}",
	"\t\t//#endregion",
	"",
].join("\n");

/** Botón nuevo, insertado antes del de "Allow once" en la fila de acciones. */
const ALWAYS_BUTTON =
	'(0, react_jsx_runtime.jsx)(_deepseek_ai_dsh_client_ui_primitives.Button, { variant: "outline", disabled: answered, onClick: () => { allowAlwaysRemember(pending); answer("allowed-once"); }, children: t("allowAlways", { toolName: pending.toolName }) }), ';

/**
 * Anclajes del parche. `from` literal se aplica con split/join (sin semántica
 * de reemplazo); `pattern` se aplica como regex única con reemplazo funcional.
 */
const EDITS = [
	{
		name: "diccionario en → clave allowAlways",
		from: 'allowOnce: "Allow once"',
		to: 'allowOnce: "Allow once", allowAlways: "Always allow {toolName}"',
	},
	{
		name: "diccionario zh → clave allowAlways",
		from: 'allowOnce: "允许一次"',
		to: 'allowOnce: "允许一次", allowAlways: "始终允许 {toolName}"',
	},
	{
		name: "helpers de memoria de sesión",
		from: "let nextApprovalKey = 0;",
		to: HELPERS + "\t\tlet nextApprovalKey = 0;",
	},
	{
		name: "respuesta automática para un tool ya autorizado",
		from: "if (sessionId === void 0) return next();",
		to: 'if (sessionId === void 0) return next();\n\t\t\tif (allowAlwaysGranted(sessionId, request.toolName)) return "allowed-once";',
	},
	{
		name: "botón Always allow",
		pattern: /\(0, react_jsx_runtime\.jsx\)\(_deepseek_ai_dsh_client_ui_primitives\.Button, \{\s*variant: "primary",[\s\S]*?children: t\("allowOnce"\)\s*\}\)/,
		to: (matched) => ALWAYS_BUTTON + matched,
	},
];

// ---------------------------------------------------------------------------
// Resolución de instalaciones (misma lógica que el wrapper `dsh`)
// ---------------------------------------------------------------------------

/** Rutas candidatas al bundle del panel. */
function clientCandidates() {
	const found = new Set();
	const add = (path) => {
		if (path !== undefined && existsSync(path)) found.add(path);
	};
	const install = process.env.DSH_INSTALL;
	if (install !== undefined && install !== "") add(join(dirname(install), CLIENT_REL));
	const scopes = [
		join(homedir(), ".dsh", "profiles", "node_modules", "@deepseek-ai"),
		join(homedir(), ".dsh", "profiles", "web", "node_modules", "@deepseek-ai"),
	];
	for (const scope of scopes) add(join(scope, CLIENT_REL));
	const npxRoot = join(homedir(), ".npm", "_npx");
	if (existsSync(npxRoot)) {
		for (const entry of readdirSync(npxRoot)) add(join(npxRoot, entry, "node_modules", "@deepseek-ai", CLIENT_REL));
	}
	// Un enlace de perfil y su caché apuntan al mismo archivo: deduplicar.
	const real = new Map();
	for (const path of found) {
		let key = path;
		try {
			key = realpathSync(path);
		} catch {}
		if (!real.has(key)) real.set(key, path);
	}
	return [...real.values()];
}

/** Versión del paquete dsh que acompaña al bundle. */
function versionOf(clientPath) {
	const scope = dirname(dirname(dirname(clientPath)));
	for (const candidate of [join(scope, "dsh", "package.json"), join(dirname(dirname(clientPath)), "package.json")]) {
		try {
			return JSON.parse(readFileSync(candidate, "utf8")).version ?? "?";
		} catch {}
	}
	return "?";
}

/** Descompone una versión en base numérica y pre-release. */
function versionKey(raw) {
	const dash = raw.indexOf("-");
	const base = dash === -1 ? raw : raw.slice(0, dash);
	return {
		base: base.split(".").map((part) => Number.parseInt(part, 10) || 0),
		pre: dash === -1 ? "" : raw.slice(dash + 1),
	};
}

/** ¿`candidate` es más nueva que `current`? Una release gana a su pre-release. */
function isNewer(candidate, current) {
	const next = versionKey(candidate);
	const current_ = versionKey(current);
	for (let index = 0; index < 3; index += 1) {
		const left = next.base[index] ?? 0;
		const right = current_.base[index] ?? 0;
		if (left !== right) return left > right;
	}
	if (next.pre === current_.pre) return false;
	if (next.pre === "") return true;
	if (current_.pre === "") return false;
	return next.pre > current_.pre;
}

// ---------------------------------------------------------------------------
// Parche
// ---------------------------------------------------------------------------

/** Aplica los anclajes o falla sin escribir nada. */
function patchSource(source) {
	let out = source;
	for (const edit of EDITS) {
		if (edit.pattern !== undefined) {
			const matches = out.match(new RegExp(edit.pattern.source, `${edit.pattern.flags}g`));
			if (matches === null || matches.length !== 1) {
				throw new Error(`anclaje "${edit.name}": ${String(matches?.length ?? 0)} coincidencias (se esperaba 1)`);
			}
			out = out.replace(edit.pattern, edit.to);
			continue;
		}
		const parts = out.split(edit.from);
		if (parts.length !== 2) {
			throw new Error(`anclaje "${edit.name}": ${String(parts.length - 1)} coincidencias (se esperaba 1)`);
		}
		out = parts.join(edit.to);
	}
	if (!out.includes(MARK)) throw new Error("el resultado no lleva la marca de parche");
	return out;
}

/** Comprueba la sintaxis del archivo ya escrito. */
function syntaxCheck(path) {
	execFileSync(process.execPath, ["--check", path], { stdio: "pipe" });
}

/** Parchea (o informa de) un bundle concreto. */
function handle(clientPath, { check, restore, quiet }) {
	const version = versionOf(clientPath);
	const label = `${clientPath} (dsh ${version})`;
	const backup = `${clientPath}.dsh-orig`;

	if (restore) {
		if (!existsSync(backup)) throw new Error(`no hay respaldo en ${backup}`);
		copyFileSync(backup, clientPath);
		syntaxCheck(clientPath);
		if (!quiet) console.log(`dsh-patch-approval: restaurado ${label}`);
		return "restored";
	}

	const source = readFileSync(clientPath, "utf8");
	if (source.includes(MARK)) {
		if (!quiet) console.log(`dsh-patch-approval: ya parcheado ${label}`);
		return "already";
	}
	if (check) {
		if (!quiet) console.log(`dsh-patch-approval: sin parchear ${label}`);
		return "missing";
	}

	const patched = patchSource(source);
	// `node --check` solo acepta extensiones conocidas: validar en un temporal
	// .js y publicar con un rename atómico dentro del propio directorio.
	const checkPath = join(tmpdir(), `dsh-patch-approval-${String(process.pid)}.js`);
	const staging = `${clientPath}.dsh-staging`;
	writeFileSync(checkPath, patched);
	try {
		syntaxCheck(checkPath);
	} catch (error) {
		const detail = error instanceof Error ? (error.message.split("\n")[0] ?? error.message) : String(error);
		throw new Error(`el parche no compila (${detail})`);
	} finally {
		unlinkSync(checkPath);
	}
	writeFileSync(staging, patched);
	if (!existsSync(backup)) copyFileSync(clientPath, backup);
	renameSync(staging, clientPath);
	if (statSync(clientPath).size === 0) throw new Error(`quedó vacío: ${clientPath}`);
	if (!quiet) console.log(`dsh-patch-approval: parcheado ${label}`);
	return "patched";
}

/** Punto de entrada. */
function main() {
	const args = process.argv.slice(2);
	const flags = {
		all: args.includes("--all"),
		check: args.includes("--check"),
		quiet: args.includes("--quiet"),
		restore: args.includes("--restore"),
		test: args.includes("--test"),
	};
	for (const arg of args) {
		if (!["--all", "--check", "--quiet", "--restore", "--test"].includes(arg)) {
			console.error(`dsh-patch-approval: opción desconocida ${arg}`);
			process.exitCode = 2;
			return;
		}
	}

	const candidates = clientCandidates();
	if (candidates.length === 0) {
		console.error("dsh-patch-approval: no encuentro ninguna instalación de @deepseek-ai/dsh-client-ui-approval");
		process.exitCode = 1;
		return;
	}
	const ranked = candidates
		.map((path) => ({ path, version: versionOf(path) }))
		.sort((left, right) => (isNewer(left.version, right.version) ? -1 : isNewer(right.version, left.version) ? 1 : 0));
	const targets = flags.all ? ranked : ranked.slice(0, 1);
	for (const skipped of ranked.slice(targets.length)) {
		if (!flags.quiet) console.log(`dsh-patch-approval: omitida versión antigua ${skipped.path} (dsh ${skipped.version})`);
	}

	let patchedAny = false;
	for (const target of targets) {
		try {
			const result = handle(target.path, flags);
			if (result === "patched") patchedAny = true;
		} catch (error) {
			console.error(`dsh-patch-approval: ${target.path}: ${error instanceof Error ? error.message : String(error)}`);
			process.exitCode = 1;
			return;
		}
	}
	if (patchedAny && !flags.quiet) {
		console.log('dsh-patch-approval: el panel tendrá "Always allow" tras recargar la pestaña (el HMR del GUI lo recarga solo).');
	}
	if (flags.test) {
		const testPath = process.env.DSH_APPROVAL_TEST;
		if (testPath === undefined || !existsSync(testPath)) {
			console.error("dsh-patch-approval: --test necesita DSH_APPROVAL_TEST apuntando al arnés de pruebas");
			process.exitCode = 1;
			return;
		}
		for (const target of targets) {
			execFileSync(process.execPath, [testPath, target.path], { stdio: "inherit" });
			console.log(`dsh-patch-approval: prueba de comportamiento OK en ${target.path}`);
		}
	}
}

main();
