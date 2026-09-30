-- Espacio r: ejecutar el archivo actual con el intérprete de su lenguaje.
-- Dentro del entorno tmux usa la terminal de abajo; si no, una terminal de
-- Neovim. Guarda antes de ejecutar.
local M = {}

local runners = {
  sh = { "bash" },
  bash = { "bash" },
  python = { "python3" },
  javascript = { "node" },
  -- Node 24 ejecuta TypeScript eliminando los tipos (sin comprobarlos).
  typescript = { "node" },
  lua = { "nvim", "-l" },
}

local function terminal_pane()
  if not vim.env.TMUX or vim.fn.executable("tmux") ~= 1 then return nil end
  local out = vim.system({ "tmux", "list-panes", "-F", "#{pane_id} #{@entorno_role}" }, { text = true }):wait()
  if out.code ~= 0 then return nil end
  for line in out.stdout:gmatch("[^\n]+") do
    local id, role = line:match("^(%S+)%s+(%S*)")
    if role == "terminal" then return id end
  end
end

function M.run()
  local file = vim.api.nvim_buf_get_name(0)
  local ft = vim.bo.filetype
  local runner = runners[ft]
  if file == "" then
    vim.notify("Guarda primero el archivo con un nombre (:w nombre)", vim.log.levels.WARN)
    return
  end
  if not runner then
    local hint = ({
      html = "abre el HTML en el navegador o usa npm run dev en un proyecto Vite",
      typescriptreact = "los componentes React se ven con npm run dev",
      javascriptreact = "los componentes React se ven con npm run dev",
      dockerfile = "construye con: docker build -t mi-imagen .",
      ["yaml.docker-compose"] = "arranca con: docker compose up",
    })[ft] or "no hay intérprete configurado para este tipo de archivo"
    vim.notify("No se puede ejecutar directamente: " .. hint, vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(runner[1]) ~= 1 then
    vim.notify("Falta el programa " .. runner[1] .. " para ejecutar este archivo", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then vim.cmd("silent write") end

  local parts = {}
  for _, part in ipairs(runner) do parts[#parts + 1] = vim.fn.shellescape(part) end
  local command = table.concat(parts, " ") .. " " .. vim.fn.shellescape(file)

  local pane = terminal_pane()
  if pane then
    vim.system({ "tmux", "send-keys", "-t", pane, "-l", "clear; " .. command }):wait()
    vim.system({ "tmux", "send-keys", "-t", pane, "Enter" }):wait()
    vim.notify("Ejecutando en la terminal de abajo: " .. vim.fn.fnamemodify(file, ":t"))
  else
    vim.cmd("botright 12split")
    vim.cmd.terminal(command)
  end
end

return M
