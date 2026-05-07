--- Schema downloader using git clone/pull.
--- :YamlSchemaSync clones repos on first run, pulls on subsequent runs.
--- Static schemas (compose, ansible, helm) are downloaded via curl.

local path_mod = require("evgenkot.yaml-schemas.path")
local registry = require("evgenkot.yaml-schemas.registry")

local M = {}

---@class SyncResult
---@field total integer
---@field success integer
---@field failed integer
---@field errors table<string, string>

--- Run a shell command async via jobstart.
---@param cmd string[]
---@param cwd? string
---@param callback fun(success: boolean, output?: string)
local function run_async(cmd, cwd, callback)
  local output = {}

  vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then output[#output + 1] = line end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then output[#output + 1] = line end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        callback(true, table.concat(output, "\n"))
      else
        callback(false, table.concat(output, "\n"))
      end
    end,
  })
end

--- Download a single file via curl.
---@param url string
---@param dest string
---@param callback fun(success: boolean, err?: string)
function M.download(url, dest, callback)
  local dir = vim.fn.fnamemodify(dest, ":h")
  vim.fn.mkdir(dir, "p")

  run_async({ "curl", "-sSfL", "-o", dest, url }, nil, function(ok, output)
    if ok then
      callback(true)
    else
      callback(false, output or "curl failed")
    end
  end)
end

--- Clone or pull the Kubernetes JSON schema repo (sparse checkout for one version only).
---@param on_progress fun(msg: string)
---@param on_complete fun(success: boolean, err?: string)
function M.sync_kubernetes(on_progress, on_complete)
  local source = registry.kubernetes_source
  local dest = path_mod.base_dir .. "/kubernetes-repo"

  if vim.fn.isdirectory(dest .. "/.git") == 1 then
    -- Already cloned — just pull
    on_progress("Updating Kubernetes schemas (git pull)...")
    run_async({ "git", "pull", "--ff-only" }, dest, function(ok, output)
      if ok then
        on_complete(true)
      else
        on_complete(false, output)
      end
    end)
  else
    -- First time — sparse clone
    on_progress("Cloning Kubernetes schemas (sparse, depth 1)...")
    vim.fn.mkdir(path_mod.base_dir, "p")

    run_async({
      "git", "clone",
      "--depth", "1",
      "--filter=blob:none",
      "--sparse",
      "https://github.com/" .. source.repo .. ".git",
      dest,
    }, nil, function(ok, output)
      if not ok then
        on_complete(false, "Clone failed: " .. (output or ""))
        return
      end

      -- Set sparse-checkout to only the version we need
      run_async({
        "git", "sparse-checkout", "set", source.path_prefix,
      }, dest, function(sparse_ok, sparse_output)
        if sparse_ok then
          on_complete(true)
        else
          on_complete(false, "Sparse checkout failed: " .. (sparse_output or ""))
        end
      end)
    end)
  end
end

--- Clone or pull the CRDs catalog repo.
---@param on_progress fun(msg: string)
---@param on_complete fun(success: boolean, err?: string)
function M.sync_crds(on_progress, on_complete)
  local source = registry.crds_source
  local dest = path_mod.base_dir .. "/crds-repo"

  if vim.fn.isdirectory(dest .. "/.git") == 1 then
    on_progress("Updating CRDs catalog (git pull)...")
    run_async({ "git", "pull", "--ff-only" }, dest, function(ok, output)
      if ok then
        on_complete(true)
      else
        on_complete(false, output)
      end
    end)
  else
    on_progress("Cloning CRDs catalog (depth 1)...")
    vim.fn.mkdir(path_mod.base_dir, "p")

    run_async({
      "git", "clone",
      "--depth", "1",
      "https://github.com/" .. source.repo .. ".git",
      dest,
    }, nil, function(ok, output)
      if ok then
        on_complete(true)
      else
        on_complete(false, "Clone failed: " .. (output or ""))
      end
    end)
  end
end

--- Download all static entries (compose, ansible, helm) via curl.
---@param on_complete fun(downloaded: integer, failed: integer)
function M.sync_static(on_complete)
  local entries = registry.static_entries
  local total = #entries
  local downloaded = 0
  local failed = 0
  local completed = 0

  if total == 0 then
    on_complete(0, 0)
    return
  end

  for _, entry in ipairs(entries) do
    local dest = path_mod.resolve(entry)
    M.download(entry.url, dest, function(ok, _)
      completed = completed + 1
      if ok then
        downloaded = downloaded + 1
      else
        failed = failed + 1
      end
      if completed == total then
        on_complete(downloaded, failed)
      end
    end)
  end
end

--- Full sync: clone/pull both repos + download static schemas.
---@param on_complete fun(result: SyncResult)
---@param on_progress? fun(msg: string)
function M.download_all(on_complete, on_progress)
  local result = { total = 0, success = 0, failed = 0, errors = {} }
  local phases_done = 0
  local total_phases = 3

  local function check_done()
    if phases_done == total_phases then
      on_complete(result)
    end
  end

  local function progress(msg)
    if on_progress then
      on_progress(msg)
    end
  end

  -- Phase 1: Kubernetes
  M.sync_kubernetes(progress, function(ok, err)
    phases_done = phases_done + 1
    if ok then
      result.success = result.success + 1
    else
      result.failed = result.failed + 1
      result.errors["kubernetes"] = err or "unknown error"
    end
    result.total = result.total + 1
    check_done()
  end)

  -- Phase 2: CRDs
  M.sync_crds(progress, function(ok, err)
    phases_done = phases_done + 1
    if ok then
      result.success = result.success + 1
    else
      result.failed = result.failed + 1
      result.errors["crds"] = err or "unknown error"
    end
    result.total = result.total + 1
    check_done()
  end)

  -- Phase 3: Static schemas
  M.sync_static(function(downloaded, phase_failed)
    phases_done = phases_done + 1
    result.success = result.success + downloaded
    result.failed = result.failed + phase_failed
    result.total = result.total + downloaded + phase_failed
    check_done()
  end)
end

return M
