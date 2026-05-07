local M = {}

--- Base directory for all schemas
M.base_dir = vim.fn.expand("~/.local/share/yaml-schemas")

--- Returns the full local path for a schema entry.
--- For kubernetes: points into the cloned repo's sparse-checkout dir.
--- For crds: points into the cloned crds-repo.
--- For static (compose, ansible, helm): points to base_dir/category/filename.
---@param entry SchemaEntry
---@return string
function M.resolve(entry)
  if entry.category == "kubernetes" then
    local registry = require("evgenkot.yaml-schemas.registry")
    return M.base_dir .. "/kubernetes-repo/" .. registry.kubernetes_source.path_prefix .. "/" .. entry.local_filename
  elseif entry.category == "crds" then
    return M.base_dir .. "/crds-repo/" .. entry.local_filename
  else
    return M.base_dir .. "/" .. entry.category .. "/" .. entry.local_filename
  end
end

--- Checks if a schema file exists locally.
---@param entry SchemaEntry
---@return boolean
function M.exists(entry)
  return vim.fn.filereadable(M.resolve(entry)) == 1
end

return M
