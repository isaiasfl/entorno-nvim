local M = {}
local paths = require("config.paths")
local profile = require("config.profile")

local tailwind_config_names = {
  "tailwind.config.js",
  "tailwind.config.cjs",
  "tailwind.config.mjs",
  "tailwind.config.ts",
  "tailwind.config.cts",
  "tailwind.config.mts",
}

local tailwind_ignored_directories = {
  [".git"] = true,
  [".next"] = true,
  ["build"] = true,
  ["coverage"] = true,
  ["dist"] = true,
  ["node_modules"] = true,
}

local function content_uses_tailwind_css(content)
  return content:match("@import%s+['\"]tailwindcss[%s/'\"]") ~= nil
    or content:match("@tailwind%s+[%w_-]+") ~= nil
    or content:match("@config%s+['\"]") ~= nil
end

local function package_uses_tailwind(path)
  local read_ok, lines = pcall(vim.fn.readfile, path)
  if not read_ok then
    return false
  end

  local ok, package = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok or type(package) ~= "table" then
    return false
  end

  for _, field in ipairs({ "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" }) do
    if type(package[field]) == "table" and package[field].tailwindcss then
      return true
    end
  end

  return false
end

local function has_tailwind_config(directory)
  for _, name in ipairs(tailwind_config_names) do
    if vim.uv.fs_stat(vim.fs.joinpath(directory, name)) then
      return true
    end
  end
  return false
end

local function buffer_has_tailwind_css(bufnr)
  if vim.bo[bufnr].filetype ~= "css" then
    return false
  end

  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  return content_uses_tailwind_css(content)
end

local function tailwind_css_entries(root)
  local directories = { root }
  local entries = {}
  local inspected = 0

  while #directories > 0 and inspected < 2000 and #entries < 20 do
    local directory = table.remove(directories, 1)
    local children = {}
    for name, kind in vim.fs.dir(directory) do
      children[#children + 1] = { name = name, kind = kind }
    end
    table.sort(children, function(left, right)
      return left.name < right.name
    end)

    for _, child in ipairs(children) do
      inspected = inspected + 1
      local path = vim.fs.joinpath(directory, child.name)
      if child.kind == "directory" and not tailwind_ignored_directories[child.name] then
        directories[#directories + 1] = path
      elseif child.kind == "file" and child.name:match("%.css$") then
        local ok, lines = pcall(vim.fn.readfile, path)
        if ok and content_uses_tailwind_css(table.concat(lines, "\n")) then
          entries[#entries + 1] = path
        end
      end
    end
  end

  return entries
end

local function prepare_tailwind(_, config)
  config.settings = config.settings or {}
  config.settings.editor = config.settings.editor or {}
  config.settings.editor.tabSize = vim.lsp.util.get_effective_tabstop()

  if has_tailwind_config(config.root_dir) then
    return
  end

  local entries = tailwind_css_entries(config.root_dir)
  local config_file = {}
  for _, path in ipairs(entries) do
    local relative = vim.fs.relpath(config.root_dir, path)
    local directory = vim.fs.dirname(relative)
    config_file[relative] = directory == "." and "**/*" or directory .. "/**"
  end
  if next(config_file) then
    config.settings.tailwindCSS = config.settings.tailwindCSS or {}
    config.settings.tailwindCSS.experimental = config.settings.tailwindCSS.experimental or {}
    config.settings.tailwindCSS.experimental.configFile = config_file
  end
end

function M.tailwind_root(bufnr, on_dir)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end

  local directory = vim.fs.dirname(filename)
  local css_evidence = buffer_has_tailwind_css(bufnr)
  local css_root

  while directory do
    local package_path = vim.fs.joinpath(directory, "package.json")
    if vim.uv.fs_stat(package_path) and package_uses_tailwind(package_path) then
      on_dir(directory)
      return
    end
    if has_tailwind_config(directory) then
      on_dir(directory)
      return
    end
    if css_evidence and not css_root then
      local has_project_marker = vim.uv.fs_stat(package_path) or vim.uv.fs_stat(vim.fs.joinpath(directory, ".git"))
      if has_project_marker then
        css_root = directory
      end
    end

    local parent = vim.fs.dirname(directory)
    if not parent or parent == directory then
      break
    end
    directory = parent
  end

  if css_evidence then
    on_dir(css_root or vim.fs.dirname(filename))
  end
end

local function typescript_root(bufnr, on_dir)
  local lockfiles = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
  local project_markers = vim.list_extend(vim.deepcopy(lockfiles), { "package.json", ".git" })
  local project_marker_set = {}
  for _, marker in ipairs(project_markers) do
    project_marker_set[marker] = true
  end
  -- Elegir el marcador mas cercano. Los grupos anidados priorizaban cualquier
  -- lockfile superior (incluso en HOME) sobre el package.json del proyecto.
  local project_root = vim.fs.root(bufnr, function(name)
    return project_marker_set[name] == true
  end)
  local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
  local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })

  if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
    return
  end
  if deno_root and (not project_root or #deno_root >= #project_root) then
    return
  end

  on_dir(project_root or vim.fn.getcwd())
end

M.web_servers = {
  tailwindcss = {
    executable = "tailwindcss-language-server",
    args = { "--stdio" },
    config = {
      before_init = prepare_tailwind,
      root_dir = M.tailwind_root,
    },
  },
  ts_ls = {
    executable = "typescript-language-server",
    args = { "--stdio" },
    config = { root_dir = typescript_root },
  },
  html = {
    executable = "vscode-html-language-server",
    args = { "--stdio" },
    config = { settings = { html = {}, css = {}, javascript = {} } },
  },
  cssls = { executable = "vscode-css-language-server", args = { "--stdio" } },
  jsonls = { executable = "vscode-json-language-server", args = { "--stdio" } },
}

local function map(bufnr, lhs, callback, description)
  vim.keymap.set("n", lhs, callback, {
    buffer = bufnr,
    desc = description,
    silent = true,
  })
end

function M.attach(bufnr)
  if not profile.has("diagnostics") then return end
  map(bufnr, "gd", vim.lsp.buf.definition, "LSP: Ir a la definicion")
  map(bufnr, "gD", vim.lsp.buf.declaration, "LSP: Ir a la declaracion")
  map(bufnr, "<leader>lf", function()
    vim.lsp.buf.format({ bufnr = bufnr })
  end, "LSP: Formatear buffer")
end

function M.enable(name, config)
  vim.lsp.config(name, config or {})
  vim.lsp.enable(name)
end

local function enable_web_servers()
  local bin_dir = paths.web_lsp_bin()

  for name, server in pairs(M.web_servers) do
    local executable = vim.fs.joinpath(bin_dir, server.executable)
    if vim.fn.executable(executable) ~= 1 then
      profile.unavailable(name, "ejecute scripts/instalar-lsp-web.sh")
    else
      local config = vim.tbl_deep_extend("force", vim.deepcopy(server.config or {}), {
        cmd = vim.list_extend({ executable }, vim.deepcopy(server.args)),
      })
      M.enable(name, config)
    end
  end
end

local function enable_lua_server()
  local executable = paths.luals_bin()
  if vim.fn.executable(executable) ~= 1 then
    profile.unavailable("lua_ls", "ejecute scripts/instalar-luals.sh")
    return
  end

  local runtime = vim.env.VIMRUNTIME
  if not runtime or runtime == "" or not vim.uv.fs_stat(runtime) then
    error("No se pudo determinar el runtime de Neovim para LuaLS")
  end

  local log_dir = paths.luals_log_dir()
  M.enable("lua_ls", {
    cmd = { executable, "--logpath=" .. log_dir },
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = { "lua/?.lua", "lua/?/init.lua" },
        },
        diagnostics = { globals = { "vim" } },
        workspace = {
          checkThirdParty = "Disable",
          library = { runtime },
          ignoreDir = { ".backups", ".git", ".xdg", "node_modules" },
          useGitIgnore = true,
        },
      },
    },
  })
end

local function enable_python_server()
  local executable = vim.fs.joinpath(paths.python_lsp_bin(), "pyright-langserver")
  if vim.fn.executable(executable) ~= 1 then
    profile.unavailable("pyright", "ejecute scripts/instalar-lsp-python.sh")
    return
  end

  M.enable("pyright", {
    cmd = { executable, "--stdio" },
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          typeCheckingMode = "basic",
          useLibraryCodeForTypes = true,
        },
      },
    },
  })
end

function M.setup()
  vim.diagnostic.config({ update_in_insert = true })
  vim.diagnostic.enable(profile.has("diagnostics"))
  if not require("config.lazy").available then
    profile.unavailable("LSP", "prepare plugins y servidores; :EntornoInfo muestra el perfil")
    return
  end

  local group = vim.api.nvim_create_augroup("entorno_nvim_lsp", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      M.attach(event.buf)
    end,
  })

  if profile.has("web") then enable_web_servers() end
  if profile.has("lua") then enable_lua_server() end
  if profile.has("python") then enable_python_server() end
end

return M
