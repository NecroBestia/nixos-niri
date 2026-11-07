# Command inject V2

Small native OpenCode V2 replacement for the old V1 command-inject plugin.
It exposes Makefile targets and `package.json` scripts as commands that inject
the exact shell command into the agent prompt. It supports the package manager
declared in `packageManager`, falling back to npm.
