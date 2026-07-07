vim.pack.add({
    -- ==========================================
    -- Temas Visuales (Colores y Estética)
    -- ==========================================
    -- Tema moderno, tonos fríos y neón (inspirado en Tokio de noche).
    "https://github.com/folke/tokyonight.nvim", 
    -- Tema cálido, tonos oscuros y relajantes (inspirado en arte japonés).
    "https://github.com/rebelot/kanagawa.nvim", 
    -- Tema muy oscuro con alto contraste, excelente para concentrarse.
    { src = "https://github.com/bluz71/vim-moonfly-colors", name = "moonfly" }, 

    -- ==========================================
    -- Plugins (El Motor de tu Flujo de Trabajo)
    -- ==========================================
    -- Terminal y Ejecución
      -- Terminal flotante rápida. Ideal para ejecutar scripts o compilar sin salir del código.
    { src = "https://github.com/akinsho/toggleterm.nvim", version = "main", config = true },

    -- Herramientas para la Universidad y Matemáticas
        -- El motor definitivo para LaTeX. Compila a PDF, sincroniza visores y entiende sintaxis matemática.
    "https://github.com/lervag/vimtex",
        -- Embellece archivos Markdown. Oculta asteriscos/numerales y renderiza fórmulas y tablas en tiempo real.
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim", branch = "main" }, 

    -- Ecosistema Core y Utilidades
        -- Tu navaja suiza. Maneja el explorador de archivos, buscador global, barra inferior, pantalla de inicio y sesiones.
    "https://github.com/nvim-mini/mini.nvim", 
        -- Diccionario gigante de fragmentos de código (ej: escribes "frac" y te arma la fracción en LaTeX).
    "https://github.com/rafamadriz/friendly-snippets", 
        -- Cursores tipo VS CODE 
    { src = "https://github.com/jake-stewart/multicursor.nvim" },
        -- Plugins para el Modo de Concentración
    "https://github.com/folke/zen-mode.nvim",
    "https://github.com/folke/twilight.nvim",
    -- Inteligencia y Análisis de Código
        -- El "cerebro" semántico. Lee la estructura de tu código para dar colores perfectos y permitir el plegado (folding).
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },     
        -- El puente para los "Language Servers". Te da autocompletado inteligente y subraya errores de sintaxis mientras escribes.
    "https://github.com/neovim/nvim-lspconfig",                           
    -- Control de Versiones
        -- Integración absoluta con Git. Te permite hacer commits, push y ver el historial del proyecto sin usar la terminal externa.
    "https://github.com/tpope/vim-fugitive",                              

  })


