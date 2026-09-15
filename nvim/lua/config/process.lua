local M = {}

-- Solo las integraciones con aplicaciones personales recuperan el entorno
-- XDG original. El editor y sus servidores mantienen sus directorios privados.
function M.desktop_env()
  if vim.env.ENTORNO_DESKTOP_ENV_SAVED ~= "1" then
    return nil
  end
  return {
    XDG_CONFIG_HOME = vim.env.ENTORNO_DESKTOP_CONFIG_HOME,
    XDG_DATA_HOME = vim.env.ENTORNO_DESKTOP_DATA_HOME,
    XDG_STATE_HOME = vim.env.ENTORNO_DESKTOP_STATE_HOME,
    XDG_CACHE_HOME = vim.env.ENTORNO_DESKTOP_CACHE_HOME,
  }
end

return M
