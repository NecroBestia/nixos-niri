#!/usr/bin/env node
/**
 * Prueba de comportamiento del bundle del panel de aprobación:
 *  1. el panel renderiza tres botones (Reject / Always allow <tool> / Allow once);
 *  2. pulsar "Always allow" responde 'allowed-once' y recuerda el tool;
 *  3. una segunda petición del mismo tool en la misma sesión se responde sola,
 *     sin abrir panel;
 *  4. otro tool, u otra sesión, vuelven a preguntar.
 *
 * El árbol instalado no trae react como paquete resoluble desde Node (el shell
 * lo bundlea y lo expone al loader de plugins), así que aquí va un shim mínimo
 * de createElement/jsx + un renderer estático: basta para comprobar la
 * estructura del panel y el cableado de onClick.
 *
 * Uso: node test-approval.mjs <ruta-client.js>
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

// --- shim de React ---------------------------------------------------------
const escapeHtml = (value) =>
	String(value).replace(/[&<>"]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[char]);

const jsx = (type, props, key) => ({ type, props: props ?? {}, key });
const createElement = (type, props, ...children) => ({
	type,
	props: { ...(props ?? {}), children: children.length <= 1 ? children[0] : children },
});

/** Render estático: componentes función + elementos anfitrión. */
function render(node) {
	if (node === null || node === undefined || typeof node === "boolean") return "";
	if (Array.isArray(node)) return node.map(render).join("");
	if (typeof node === "string" || typeof node === "number") return escapeHtml(node);
	const { type, props } = node;
	if (typeof type === "function") return render(type(props));
	const attributes = [];
	if (props.className !== undefined) attributes.push(`class="${escapeHtml(props.className)}"`);
	if (props.disabled === true) attributes.push("disabled");
	return `<${type}${attributes.length === 0 ? "" : ` ${attributes.join(" ")}`}>${render(props.children)}</${type}>`;
}

const React = { createElement, useState: (initial) => [initial, () => {}] };
const jsxRuntime = { jsx, jsxs: jsx, Fragment: Symbol("Fragment") };

// --- entorno de navegador simulado ----------------------------------------
const storage = new Map();
const sessionStorage = {
	getItem: (key) => (storage.has(key) ? storage.get(key) : null),
	setItem: (key, value) => storage.set(key, String(value)),
	removeItem: (key) => storage.delete(key),
};

let loaded;
globalThis.window = { __ModuleLoader__: { load: (mod) => (loaded = mod) }, sessionStorage };

const buttons = [];
const stubs = {
	"react/jsx-runtime": jsxRuntime,
	react: React,
	"@deepseek-ai/dsh-client-ui-primitives": {
		Button: (props) => {
			buttons.push(props);
			return createElement("button", { disabled: props.disabled, onClick: props.onClick }, props.children);
		},
	},
};

// --- carga del bundle ------------------------------------------------------
const TARGET = process.argv[2];
(0, eval)(readFileSync(TARGET, "utf8"));
assert.ok(loaded, "el bundle no llamó a window.__ModuleLoader__.load");
const plugin = loaded.factory((specifier) => {
	if (!(specifier in stubs)) throw new Error(`require inesperado: ${specifier}`);
	return stubs[specifier];
});
assert.equal(typeof plugin.apply, "function", "el plugin no exporta apply");
assert.ok(Array.isArray(plugin.inject) && plugin.inject.includes("sessions"), "inject inesperado");

// --- contexto del cliente simulado ----------------------------------------
const dictionary = {
	waiting: "Waiting for approval",
	"detail.aria": "Approval details",
	escalation: "Tool {toolName} requests privileged execution",
	reject: "Reject",
	allowOnce: "Allow once",
	allowAlways: "Always allow {toolName}",
};
const t = (key, params) =>
	params === undefined
		? (dictionary[key] ?? key)
		: (dictionary[key] ?? key).replace(/\{(\w+)\}/g, (_, name) => String(params[name]));

let panel;
let listener;
let pending;
let interactions = 0;
let session = "sesion-1";
const ctx = {
	effect: (fn) => fn(),
	locale: { register: () => {} },
	sessions: { scopeOf: () => session },
	uiSession: {
		registerPendingInteraction: () => (created) => {
			interactions += 1;
			pending = created;
			return () => {};
		},
	},
	slots: {
		inject: (_name, fn) => fn(),
		register: (_options, component) => {
			panel = component;
			return () => {};
		},
	},
	remote: {
		$on: (_event, handler) => {
			listener = handler;
		},
	},
};
plugin.apply(ctx);
assert.ok(panel !== undefined, "apply() no registró el panel");
assert.ok(listener !== undefined, "apply() no registró el listener de approval/request");

const owner = {};
const ask = (toolName) =>
	listener.call(owner, { toolName, reason: "motivo de prueba" }, () => Promise.resolve("unavailable"));
const renderPanel = () => render(panel({ matched: pending, renderSlot: () => null, t }));

// 1. Primera petición: panel con tres botones.
const first = ask("bash");
assert.equal(interactions, 1, "la primera petición debía abrir panel");
const html = renderPanel();
assert.ok(html.includes("Reject"), "falta el botón Reject");
assert.ok(html.includes("Allow once"), "falta el botón Allow once");
assert.ok(html.includes("Always allow bash"), `falta el botón Always allow: ${html}`);
assert.equal((html.match(/<button/g) ?? []).length, 3, "el panel no tiene tres botones");

// 2. Clic en "Always allow": responde allowed-once y guarda el permiso.
const always = buttons.find((button) => String(button.children).includes("Always allow"));
assert.ok(always, "no encontré el botón Always allow entre los renderizados");
await always.onClick();
assert.equal(await first, "allowed-once", "el panel debía responder allowed-once");
assert.deepEqual(
	JSON.parse(storage.get("dsh.approval.allowAlways:sesion-1")),
	["bash"],
	"el permiso no quedó guardado para la sesión",
);

// 3. Segunda petición del mismo tool: sin panel y respuesta automática.
const second = await ask("bash");
assert.equal(second, "allowed-once", "la segunda petición debía resolverse sola");
assert.equal(interactions, 1, "no debía abrirse otro panel para el mismo tool");

// 4. Otro tool: vuelve a preguntar.
const third = ask("write");
assert.equal(interactions, 2, "otro tool debía abrir panel de nuevo");
assert.ok(renderPanel().includes("Always allow write"), "el panel de write debía ofrecer Always allow write");
await pending.answer("rejected");
assert.equal(await third, "rejected");

// 5. Otra sesión: el permiso no se hereda.
session = "sesion-2";
const fourth = ask("bash");
assert.equal(interactions, 3, "otra sesión debía abrir panel de nuevo");
await pending.answer("rejected");
assert.equal(await fourth, "rejected");

console.log("test-approval: OK — 3 botones, permiso por tool y sesión, sin herencia entre sesiones");
