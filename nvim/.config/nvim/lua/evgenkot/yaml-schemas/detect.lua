--- Filetype detection: matches YAML files to schemas via filename patterns
--- and content-based detection (kind/apiVersion fields).

local registry = require("evgenkot.yaml-schemas.registry")

local M = {}

--- Convert a glob pattern to a Lua pattern for matching.
--- Supports: * (any chars except /), ** (any chars including /)
---@param glob string
---@return string
local function glob_to_pattern(glob)
  local pattern = glob
  -- Escape Lua magic characters (except * which we handle)
  pattern = pattern:gsub("([%.%+%-%^%$%(%)%%])", "%%%1")
  -- ** matches anything including path separators
  pattern = pattern:gsub("%*%*", "\001")
  -- * matches anything except path separators
  pattern = pattern:gsub("%*", "[^/]*")
  -- Restore ** placeholder
  pattern = pattern:gsub("\001", ".*")
  -- Anchor to end (allow any prefix path)
  return pattern .. "$"
end

--- Match a filename against all registered filename patterns.
--- Checks both the full path and just the basename.
---@param filename string
---@return SchemaEntry|nil
function M.match_filename(filename)
  local entries = registry.get_all()
  local basename = vim.fn.fnamemodify(filename, ":t")

  for _, entry in ipairs(entries) do
    if entry.filename_patterns then
      for _, pattern in ipairs(entry.filename_patterns) do
        local lua_pattern = glob_to_pattern(pattern)
        if filename:match(lua_pattern) or basename:match(lua_pattern) then
          return entry
        end
      end
    end
  end

  return nil
end

--- Match YAML content (first N lines) against content rules.
--- Looks for kind: and apiVersion: fields.
---@param lines string[]
---@return SchemaEntry|nil
function M.match_content(lines)
  local kind, api_version

  -- Parse first 20 lines for kind and apiVersion
  local max_lines = math.min(#lines, 20)
  for i = 1, max_lines do
    local line = lines[i]
    if not kind then
      local k = line:match("^kind:%s*(.+)%s*$")
      if k then kind = k end
    end
    if not api_version then
      local v = line:match("^apiVersion:%s*(.+)%s*$")
      if v then api_version = v end
    end
    if kind and api_version then break end
  end

  if not kind then return nil end

  -- Search all entries with content_match
  local entries = registry.get_all()
  for _, entry in ipairs(entries) do
    if entry.content_match then
      local match_kind = entry.content_match.kind
      local match_api = entry.content_match.apiVersion

      if match_kind and match_kind == kind then
        -- If entry also specifies apiVersion, both must match
        if match_api then
          if match_api == api_version then
            return entry
          end
        else
          return entry
        end
      end
    end
  end

  return nil
end

--- Resolve schema for a buffer. Filename match takes priority over content.
---@param bufnr integer
---@return SchemaEntry|nil
function M.resolve(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)

  -- Try filename match first (higher priority)
  local entry = M.match_filename(filename)
  if entry then return entry end

  -- Fall back to content-based detection
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 20, false)
  return M.match_content(lines)
end

return M
