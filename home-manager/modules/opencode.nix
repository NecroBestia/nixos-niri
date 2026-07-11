#===================================================================
# OPENCODE — Configuración de IA (Skills, Plugins, MCPs)
#===================================================================
# Módulo independiente con toda la configuración de opencode.
# Importado desde shared/default.nix y alimentado por los inputs
# definidos en ai-inputs.nix (ver flake.nix).
#
# DEPENDENCIAS:
#   inputs        → Skills descargadas (definidas en ai-inputs.nix)
#   pkgs-unstable → opencode desde nixpkgs-unstable
#===================================================================
{ config, pkgs, pkgs-unstable, inputs, ... }:

let
  # Atajo para builtins.path (reduce ruido visual).
  skill = path: builtins.path { inherit path; };
in {
  programs.opencode = {
    enable = true;
    package = pkgs-unstable.opencode;

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
      frontend-design    = skill "${inputs.anthropic-skills}/skills/frontend-design";
      ui-ux-pro-max      = skill "${inputs.opencode-kit}/.opencode/skills/ui-ux-pro-max";
      ui-ux-designer     = skill "${inputs.opencode-6-2026}/opencode-config/skill-libraries/web-development/ui-ux-designer";
      ui-ux-design-review = skill "${inputs.tutiendaweb-public}/.opencode/skills/ui-ux-design-review";
      frontend-ui-ux     = skill "${inputs.oh-my-opencode}/packages/shared-skills/skills/frontend";
      typeui             = skill "${inputs.typeui}/plugins/openclaw/typeui/skills/typeui";

      # Next.js / Node.js
      react-best-practices = skill "${inputs.vercel-skills}/skills/react-best-practices";

      # Desarrollo general
      mcp-builder    = skill "${inputs.anthropic-skills}/skills/mcp-builder";
      webapp-testing = skill "${inputs.anthropic-skills}/skills/webapp-testing";

      # Utilidades
      stop-slop    = skill inputs.stop-slop;
      composio-cli = skill "${inputs.composio-skills}/skills/composio-cli";
    };

    #-----------------------------------------------------------------
    # SETTINGS — Plugins y MCPs
    #-----------------------------------------------------------------
    settings = {
      plugin = [
        "superpowers@git+https://github.com/obra/superpowers.git"
        "opencode-command-inject"
        "opencode-worktree"
        "opencode-agent-memory"
        "opencode-dynamic-context-pruning"
      ];

      mcp = {
        context7 = {
          type = "local";
          command = ["npx" "-y" "@upstash/context7-mcp"];
          enabled = false;  # Bajo demanda para no ralentizar el startup
        };
      };
    };
  };
}
