--- Schema registry: hybrid static + dynamic discovery.
--- Static entries define filename-pattern-based schemas (compose, ansible, helm).
--- Dynamic entries are discovered from local disk after :YamlSchemaSync downloads them.

local path_mod = require("evgenkot.yaml-schemas.path")

---@class SchemaEntry
---@field name string
---@field category "kubernetes"|"crds"|"compose"|"ansible"|"helm"
---@field url string
---@field filename_patterns? string[]
---@field content_match? { kind?: string, apiVersion?: string }
---@field local_filename string

local M = {}

-- ============================================================
-- Remote sources for dynamic discovery (used by :YamlSchemaSync)
-- ============================================================

--- Kubernetes JSON schema repo config
M.kubernetes_source = {
  repo = "yannh/kubernetes-json-schema",
  branch = "master",
  -- Only download standalone-strict schemas for the latest version
  path_prefix = "v1.30-standalone-strict",
  base_url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30-standalone-strict/",
  category = "kubernetes",
}

--- CRDs catalog repo config
M.crds_source = {
  repo = "datreeio/CRDs-catalog",
  branch = "main",
  base_url = "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/",
  category = "crds",
}

-- ============================================================
-- Static entries (filename-pattern-based schemas)
-- ============================================================

---@type SchemaEntry[]
M.static_entries = {
  {
    name = "Docker Compose",
    category = "compose",
    url = "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json",
    filename_patterns = {
      "docker-compose.yml",
      "docker-compose.yaml",
      "docker-compose.*.yml",
      "docker-compose.*.yaml",
      "compose.yml",
      "compose.yaml",
    },
    local_filename = "docker-compose.json",
  },
  {
    name = "Ansible Playbook",
    category = "ansible",
    url = "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json",
    filename_patterns = {
      "playbook.yml",
      "playbook.yaml",
      "playbooks/*.yml",
      "playbooks/*.yaml",
      "site.yml",
      "site.yaml",
    },
    local_filename = "playbook.json",
  },
  {
    name = "Helm Chart",
    category = "helm",
    url = "https://json.schemastore.org/chart.json",
    filename_patterns = { "Chart.yaml" },
    local_filename = "chart.json",
  },
}

-- ============================================================
-- Dynamic discovery from local disk
-- ============================================================

--- Parse a Kubernetes schema filename into a content_match table.
--- Filenames follow patterns like:
---   "deployment-apps-v1.json" → { kind = "Deployment", apiVersion = "apps/v1" }
---   "service.json" → { kind = "Service", apiVersion = "v1" }
---@param filename string
---@return { kind: string, apiVersion: string }|nil
function M.parse_k8s_filename(filename)
  local base = filename:gsub("%.json$", "")
  if not base or base == "" then return nil end

  -- Pattern: kind-group-version (e.g., deployment-apps-v1)
  local kind_part, group, version = base:match("^(.+)-(%a[%w%.]*)-v(.+)$")
  if kind_part and group and version then
    -- Capitalize first letter of kind
    local kind = kind_part:sub(1, 1):upper() .. kind_part:sub(2)
    -- Handle multi-word kinds (e.g., clusterrolebinding → ClusterRoleBinding)
    -- We'll use the filename as-is for the kind and rely on content matching
    local api_version = group .. "/v" .. version
    return { kind = kind, apiVersion = api_version }
  end

  -- Pattern: kind only (core v1 resources, e.g., service.json)
  -- These are core/v1 resources
  if not base:find("-") then
    local kind = base:sub(1, 1):upper() .. base:sub(2)
    return { kind = kind, apiVersion = "v1" }
  end

  return nil
end

--- Parse a CRD schema filename into a content_match table.
--- CRD files are stored as: api_group/kind_version.json
--- e.g., "monitoring.coreos.com/servicemonitor_v1.json"
---@param api_group string  -- e.g., "monitoring.coreos.com"
---@param filename string   -- e.g., "servicemonitor_v1.json"
---@return { kind: string, apiVersion: string }|nil
function M.parse_crd_filename(api_group, filename)
  local base = filename:gsub("%.json$", "")
  if not base or base == "" then return nil end

  -- Pattern: kind_version (e.g., servicemonitor_v1)
  local kind_lower, version = base:match("^(.+)_(v.+)$")
  if kind_lower and version then
    local kind = kind_lower:sub(1, 1):upper() .. kind_lower:sub(2)
    local api_version = api_group .. "/" .. version
    return { kind = kind, apiVersion = api_version }
  end

  return nil
end

--- Scan the cloned kubernetes-repo directory and build SchemaEntry tables.
--- Looks inside the sparse-checkout path_prefix subdirectory. No network access.
---@return SchemaEntry[]
function M.discover_kubernetes()
  local entries = {}
  local dir = path_mod.base_dir .. "/kubernetes-repo/" .. M.kubernetes_source.path_prefix

  if vim.fn.isdirectory(dir) == 0 then
    return entries
  end

  local files = vim.fn.glob(dir .. "/*.json", false, true)
  for _, filepath in ipairs(files) do
    local filename = vim.fn.fnamemodify(filepath, ":t")
    -- Skip -list.json files (they are array wrappers, not useful for validation)
    if not filename:match("%-list%.json$") then
      local content_match = M.parse_k8s_filename(filename)
      if content_match then
        entries[#entries + 1] = {
          name = content_match.kind,
          category = "kubernetes",
          url = M.kubernetes_source.base_url .. filename,
          content_match = content_match,
          local_filename = filename,
        }
      end
    end
  end

  return entries
end

--- Scan the cloned crds-repo directory and build SchemaEntry tables.
--- CRDs are stored in subdirectories by API group. No network access.
---@return SchemaEntry[]
function M.discover_crds()
  local entries = {}
  local dir = path_mod.base_dir .. "/crds-repo"

  if vim.fn.isdirectory(dir) == 0 then
    return entries
  end

  -- List API group subdirectories (skip .git and other non-group dirs)
  local api_groups = vim.fn.glob(dir .. "/*", false, true)
  for _, group_path in ipairs(api_groups) do
    if vim.fn.isdirectory(group_path) == 1 then
      local api_group = vim.fn.fnamemodify(group_path, ":t")
      -- API groups contain dots (e.g., monitoring.coreos.com)
      if api_group:find("%.", 1, true) then
        local files = vim.fn.glob(group_path .. "/*.json", false, true)
        for _, filepath in ipairs(files) do
          local filename = vim.fn.fnamemodify(filepath, ":t")
          local content_match = M.parse_crd_filename(api_group, filename)
          if content_match then
            entries[#entries + 1] = {
              name = content_match.kind,
              category = "crds",
              url = M.crds_source.base_url .. api_group .. "/" .. filename,
              content_match = content_match,
              local_filename = api_group .. "/" .. filename,
            }
          end
        end
      end
    end
  end

  return entries
end

--- Get the full registry: static entries + dynamically discovered entries.
--- This scans local directories (no network).
---@return SchemaEntry[]
function M.get_all()
  local entries = {}

  -- Add static entries
  for _, entry in ipairs(M.static_entries) do
    entries[#entries + 1] = entry
  end

  -- Add dynamically discovered entries
  for _, entry in ipairs(M.discover_kubernetes()) do
    entries[#entries + 1] = entry
  end
  for _, entry in ipairs(M.discover_crds()) do
    entries[#entries + 1] = entry
  end

  return entries
end

return M
