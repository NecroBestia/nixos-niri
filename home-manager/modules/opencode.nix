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

  wolframEngine = import ../pkgs/wolfram-engine.nix { inherit pkgs; };
in
{
  home.packages = [ wolframEngine ];

  # El notifier V2 sustituye las alertas nativas para evitar duplicados.
  # Se conservan los ajustes CLI existentes y se desactiva solo el plugin
  # integrado de notificaciones.
  home.file.".config/opencode/cli.json" = {
    force = true;
    text = builtins.toJSON {
      "$schema" = "https://opencode.ai/v2/cli.json";
      theme = {
        name = "monokai";
      };
      diffs = {
        wrap = "word";
      };
      session = {
        sidebar = "auto";
        scrollbar = false;
        thinking = "show";
      };
      animations = true;
      plugins = [ "*" "-opencode.notifications" ];
    };
  };

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
    };

    #-----------------------------------------------------------------
    # SETTINGS — Plugins y MCPs
    #-----------------------------------------------------------------
    settings = {
      # OpenCode 2 requiere plugins V2 (default export con id/setup).
      # Los tres plugins locales reemplazan las implementaciones V1 que
      # todavía no publican una versión compatible. Sus README describen
      # explícitamente las diferencias funcionales con los originales.
      plugins = [
        "superpowers@git+https://github.com/obra/superpowers.git#22f0b463e7a5e579904dd6211a520321035526f7"
        "opencode-agent-memory@0.3.1"
        "opencode-supermemory@2.1.1"
        "@tarquinen/opencode-dcp@3.2.0"
        "@mohak34/opencode-notifier@latest"
        "oh-my-opencode-slim@3.0.6"
        (toString (builtins.path {
          path = ../opencode-plugins/command-inject-v2;
          name = "necro-command-inject-v2";
        }))
        (toString (builtins.path {
          path = ../opencode-plugins/tokenscope-v2;
          name = "necro-tokenscope-v2";
        }))
        (toString (builtins.path {
          path = ../opencode-plugins/deepseek-cache-v2;
          name = "necro-deepseek-cache-v2";
        }))
      ];

      permissions = [
        {
          action = "tool.use";
          resource = "supermemory_recall";
          effect = "allow";
        }
      ];

      mcp = {
        timeout = {
          startup = 60000;
          catalog = 60000;
        };

        servers = {
          context7 = {
            type = "local";
            command = [ "${pkgs.context7-mcp}/bin/context7-mcp" ];
            disabled = false;
          };

          wolfram = {
            type = "local";
            command = [
              "${wolframEngine}/bin/wolfram"
              "-run"
              "PacletSymbol[\"Wolfram/AgentTools\",\"Wolfram`AgentTools`StartMCPServer\"][]"
              "-noinit"
              "-noprompt"
            ];
            disabled = false;
            environment = {
              MCP_SERVER_NAME = "Wolfram";
            };
          };
        };
      };

      #-----------------------------------------------------------------
      # AGENTS — Subagentes especializados
      #-----------------------------------------------------------------
      # Usan system prompts estables para maximizar cache hits en DeepSeek
      # (cada subagente arranca sesión nueva, pero el prefix se cachea si
      # el prompt es consistente entre llamadas).
      #-----------------------------------------------------------------
      agents = {
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
          permissions = {
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
          permissions = {
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
          permissions = {
            edit = "allow";
            bash."*" = "deny";
          };
        };
      };
    };
  };
}
