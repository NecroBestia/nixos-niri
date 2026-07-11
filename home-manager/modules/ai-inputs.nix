#===================================================================
# AI INPUTS — Fuentes de Skills para opencode
#===================================================================
# Este archivo define TODOS los inputs relacionados con IA/skills
# que necesita el módulo opencode.nix.
#
# Se importa desde flake.nix y se mezcla con los inputs del sistema:
#   inputs = { ...system-inputs... } // (import ./home-manager/modules/ai-inputs.nix);
#
# Para agregar una skill nueva:
#   1. Añade el input aquí (url + flake = false)
#   2. Añade la skill en opencode.nix → skills.${nombre}
#===================================================================
{
  # NixOS — Skill oficial con documentación completa del sistema.
  nixos-skill = {
    url = "github:marceloeatworld/nixos-ai-skill";
    flake = false;
  };

  # Vercel — Skills de diseño web y buenas prácticas React/Next.js.
  vercel-skills = {
    url = "github:vercel-labs/agent-skills";
    flake = false;
  };

  # Anthropic — Skills oficiales de desarrollo (MCP, testing, frontend).
  anthropic-skills = {
    url = "github:anthropics/skills";
    flake = false;
  };

  # opencode-kit — Skills UI/UX adicionales.
  opencode-kit = {
    url = "github:skeletorflet/opencode-kit";
    flake = false;
  };

  # OPENCODE-6-2026 — Skills de diseño UI/UX.
  opencode-6-2026 = {
    url = "github:mohamednaeem92-max/OPENCODE-6-2026";
    flake = false;
  };

  # TuTiendaWeb — Skills de revisión de diseño UI/UX.
  tutiendaweb-public = {
    url = "github:MaxiAramayo/TuTiendaWeb-public";
    flake = false;
  };

  # oh-my-opencode — Skills de frontend compartidas.
  oh-my-opencode = {
    url = "github:code-yeongyu/oh-my-opencode";
    flake = false;
  };

  # TypeUI — Skills de diseño con paletas y layouts.
  typeui = {
    url = "github:bergside/typeui";
    flake = false;
  };

  # stop-slop — Elimina clichés y marcas de IA de textos.
  stop-slop = {
    url = "github:hardikpandya/stop-slop";
    flake = false;
  };

  # Composio — 1000+ integraciones SaaS como skill + MCP.
  composio-skills = {
    url = "github:composio-community/opencode-skills";
    flake = false;
  };
}
