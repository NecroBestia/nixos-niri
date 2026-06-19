-- =========================================================
-- Terminal Flotante y Ejecución de Comandos (runner-nvim)
-- =========================================================
local runner_ok, runner = pcall(require, "runner-nvim")
if runner_ok then
    -- Es obligatorio llamar a setup() aunque esté vacío
    runner.setup({})

    -- <leader>rc = Run Command (Abre el prompt para escribir el comando, ej: gcc main.c)
    vim.keymap.set("n", "<leader>rc", function() runner.run() end, { desc = "Ejecutar comando nuevo" })
    
    -- <leader>rl = Run Last (Repite el último comando al instante sin preguntar)
    vim.keymap.set("n", "<leader>rl", function() runner.runLast() end, { desc = "Repetir último comando" })
    
    -- <leader>rt = Run Toggle (Muestra/Oculta la ventana de la terminal sin cerrarla)
    vim.keymap.set("n", "<leader>rt", function() runner.toggle() end, { desc = "Mostrar/Ocultar terminal" })
end
