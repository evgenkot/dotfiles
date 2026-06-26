--- yaml-schemas: Local YAML schema management for yamlls.
--- Provides local schema storage, lazy downloading, and content-based detection.
--- Auto-syncs on startup (like lazy.nvim) with fidget.nvim progress spinner.

local path_mod = require("evgenkot.yaml-schemas.path")
local registry = require("evgenkot.yaml-schemas.registry")
local downloader = require("evgenkot.yaml-schemas.downloader")
local detect = require("evgenkot.yaml-schemas.detect")

local M = {}

--- Build the schemas table for yamlls settings.
--- Maps local file paths to filename patterns. No network calls.
---@return table<string, string|string[]>
function M.get_schemas()
  local schemas = {}
  local entries = registry.get_all()

  for _, entry in ipairs(entries) do
    if entry.filename_patterns then
      local local_path = path_mod.resolve(entry)
      schemas[local_path] = entry.filename_patterns
    end
  end

  return schemas
end

--- Report progress via fidget.nvim if available, otherwise vim.notify.
---@param msg string
---@param handle any|nil  fidget progress handle
---@return any|nil  updated handle
local function progress_report(msg, handle)
  local ok, fidget_progress = pcall(require, "fidget.progress")
  if ok and fidget_progress then
    if not handle then
      handle = fidget_progress.handle.create({
        title = "YamlSchemaSync",
        message = msg,
        lsp_client = { name = "yaml-schemas" },
      })
    else
      handle.message = msg
    end
  else
    vim.notify(msg, vim.log.levels.INFO)
  end
  return handle
end

--- Finish fidget progress handle.
---@param handle any|nil
---@param msg string
---@param failed boolean
local function progress_finish(handle, msg, failed)
  if handle then
    handle.message = msg
    handle:finish()
  else
    local level = failed and vim.log.levels.WARN or vim.log.levels.INFO
    vim.notify(msg, level)
  end
end

--- Download all schemas (static + dynamic discovery from both repos).
--- Async — shows progress via fidget spinner.
---@param opts? { on_complete?: fun(result: SyncResult) }
function M.sync(opts)
  opts = opts or {}
  local handle = progress_report("starting...", nil)

  downloader.download_all(function(result)
    local msg = string.format(
      "%d downloaded, %d failed",
      result.success, result.failed
    )
    progress_finish(handle, msg, result.failed > 0)

    if opts.on_complete then
      opts.on_complete(result)
    end
  end, function(msg)
    handle = progress_report(msg, handle)
  end)
end

--- Lazily download a schema if it doesn't exist locally.
---@param entry SchemaEntry
local function ensure_schema(entry)
  if not path_mod.exists(entry) then
    local dest = path_mod.resolve(entry)
    downloader.download(entry.url, dest, function(ok, err)
      if not ok then
        vim.notify(
          string.format("yaml-schemas: failed to download %s: %s", entry.name, err or "unknown"),
          vim.log.levels.WARN
        )
      end
    end)
  end
end

--- Check if repos need initial clone (first-time setup).
---@return boolean
local function needs_initial_sync()
  local k8s_dir = path_mod.base_dir .. "/kubernetes-repo/.git"
  local crds_dir = path_mod.base_dir .. "/crds-repo/.git"
  return vim.fn.isdirectory(k8s_dir) == 0 or vim.fn.isdirectory(crds_dir) == 0
end

--- Set up the :YamlSchemaSync command, auto-sync on startup, and content-based detection.
function M.setup()
  -- Register user command
  vim.api.nvim_create_user_command("YamlSchemaSync", function()
    M.sync()
  end, { desc = "Download/update all YAML schemas locally" })

  -- Content-based detection: on BufRead for yaml files, detect schema
  -- and trigger lazy download if needed
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.yaml", "*.yml", "*.yaml.j2", "*.yml.j2" },
    callback = function(ev)
      local entry = detect.resolve(ev.buf)
      if entry then
        ensure_schema(entry)
      end
    end,
    desc = "yaml-schemas: detect and lazy-download schema for YAML files",
  })

  -- Auto-sync on startup: only clone if repos don't exist yet.
  -- Updates are manual via :YamlSchemaSync.
  if needs_initial_sync() then
    vim.defer_fn(function()
      M.sync()
    end, 500)
  end
end

return M
