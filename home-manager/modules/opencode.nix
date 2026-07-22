#===================================================================
# OPENCODE — Configuración de IA (Skills, Plugins, MCPs)
#===================================================================
# Módulo independiente con toda la configuración de opencode.
# Importado desde shared/default.nix.
#
# DEPENDENCIAS:
#   inputs        → Skills descargadas (definidas en flake.nix)
#   pkgs-unstable → opencode desde nixpkgs-unstable
#===================================================================
{ pkgs-unstable, inputs, pkgs, ... }:

let
  # Atajo para builtins.path (reduce ruido visual).
  skill = path: builtins.path { inherit path; };
in
{
  programs.opencode = {
    enable = true;
    package = pkgs-unstable.opencode;
    extraPackages = with pkgs; [
      pkgs.uv                   # Solo en PATH de opencode (para graphify CLI)
    ];

    #-----------------------------------------------------------------
    # SKILLS — Conocimiento especializado para el agente
    #-----------------------------------------------------------------
    skills = {
      # Sistema
      nixos = skill inputs.nixos-skill;

      # Diseño Web
      web-design-guidelines = skill "${inputs.vercel-skills}/skills/web-design-guidelines";

      # Git
      git-release = ''
        ---
        name: git-release
        description: Create consistent releases and changelogs from merged PRs
        ---
        ## What I do
        - Draft release notes from merged PRs
        - Propose a version bump (patch/minor/major)
        - Provide a copy-pasteable `gh release create` command
      '';

      # UI/UX
      frontend-design = skill "${inputs.anthropic-skills}/skills/frontend-design";
      ui-ux-pro-max = skill "${inputs.opencode-kit}/.opencode/skills/ui-ux-pro-max";
      ui-ux-designer = skill "${inputs.opencode-6-2026}/opencode-config/skill-libraries/web-development/ui-ux-designer";
      ui-ux-design-review = skill "${inputs.tutiendaweb-public}/.opencode/skills/ui-ux-design-review";
      frontend-ui-ux = skill "${inputs.oh-my-opencode}/packages/shared-skills/skills/frontend";
      typeui = skill "${inputs.typeui}/plugins/openclaw/typeui/skills/typeui";

      # Next.js / Node.js
      react-best-practices = skill "${inputs.vercel-skills}/skills/react-best-practices";

      # Desarrollo general
      mcp-builder = skill "${inputs.anthropic-skills}/skills/mcp-builder";
      webapp-testing = skill "${inputs.anthropic-skills}/skills/webapp-testing";

      # Utilidades
      stop-slop = skill inputs.stop-slop;
      composio-cli = skill "${inputs.composio-skills}/skills/composio-cli";

      # Graphify — Knowledge graph interactivo
      graphify = skill "${inputs.graphify}/graphify/skill-opencode.md";
    };

    #-----------------------------------------------------------------
    # SETTINGS — Plugins y MCPs
    #-----------------------------------------------------------------
    settings = {
      # WARN: Las versiones deben actualizarse manualmente. Correr
      # `cat ~/.cache/opencode/packages/<plugin>/package.json` para
      # ver la versión resuelta después de un `nixos-rebuild`.
      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git#d884ae04edebef577e82ff7c4e143debd0bbec99"
        "opencode-command-inject@1.3.0"
        "opencode-worktree@0.4.1"
        "opencode-agent-memory@0.2.0"
        "@ramtinj95/opencode-tokenscope@1.8.0"
        "opencode-deepseek-cache@2.2.0"
      ];

      mcp = {
        context7 = {
          type = "local";
          command = [
            "npx"
            "-y"
            "@upstash/context7-mcp"
          ];
          enabled = false; # Bajo demanda para no ralentizar el startup
        };
      };

      #-----------------------------------------------------------------
      # AGENTS — Subagentes especializados
      #-----------------------------------------------------------------
      # Usan system prompts estables para maximizar cache hits en DeepSeek
      # (cada subagente arranca sesión nueva, pero el prefix se cachea si
      # el prompt es consistente entre llamadas).
      #-----------------------------------------------------------------
      agent = {
        code-reviewer = {
          description = "Revisa código buscando bugs, seguridad y maintainability";
          mode = "subagent";
          hidden = true;
          prompt = ''
            Eres un code reviewer experto. Tu única responsabilidad es revisar código.

            Reglas:
            - Señalá bugs, problemas de seguridad, y malas prácticas
            - Sugerí mejoras específicas con ejemplos de código
            - Sé conciso y directo
            - No escribas código nuevo, solo revisá el existente
          '';
          permission = {
            edit = "deny";
            bash."*" = "deny";
          };
        };

        debugger = {
          description = "Debuggea bugs sistemáticamente";
          mode = "subagent";
          hidden = true;
          prompt = ''
            Eres un debugger experto. Debuggeás problemas de forma sistemática.

            Metodología:
            1. Entendé el error y el contexto
            2. Identificá la causa raíz con hipótesis concretas
            3. Verificá cada hipótesis con comandos o lectura de código
            4. Proponé la solución más simple
          '';
          permission = {
            edit = "deny";
          };
        };

        refactor = {
          description = "Refactoriza código sin cambiar comportamiento";
          mode = "subagent";
          hidden = true;
          prompt = ''
            Eres un refactor engineer. Refactorizás código mejorando su estructura
            sin cambiar comportamiento.

            Principios:
            - Mantené la semántica exacta
            - Mejorá nombres de variables y funciones
            - Extraé lógica repetida en funciones reutilizables
            - Simplificá condicionales complejos
            - No cambiés APIs públicas ni firmas de funciones
          '';
          permission = {
            edit = "allow";
            bash."*" = "deny";
          };
        };
      };
    };
  };
}
