--- lemminx: the Eclipse XML Language Server.
--- Gives general XML support out of the box (validation, completion, hover,
--- formatting) driven by XSD/DTD/RelaxNG. Files that declare their own schema
--- (xsi:schemaLocation, DOCTYPE, or an <?xml-model?> PI) work automatically.
---
--- libvirt schemas
--- ===============
--- libvirt ships RelaxNG (.rng) schemas at /usr/share/libvirt/schemas/*.rng,
--- and lemminx supports RelaxNG. The tricky part is *which* schema: libvirt has
--- no single schema (domain / network / pool / nwfilter / ... each use their
--- own .rng), and everything edited through `virsh edit`, `virsh net-edit`,
--- `virsh pool-edit`, `virsh nwfilter-edit`, ... lands in an identically-named
--- temp file ($TMPDIR/virshXXXXXX.xml). So a filename pattern can't tell them
--- apart.
---
--- Instead we bind by *content*: inspect the document's root element and push a
--- per-buffer fileAssociation to lemminx (same idea as the yaml-schemas
--- content_match detection). This works for virsh temp files and for any XML
--- file with a libvirt root element, regardless of its name or location.
---
--- Pointing at the installed files (not copies) matters: several schemas are
--- thin wrappers that <include> a sibling, e.g. domain.rng -> domainoverrides
--- -> domaincommon. In-place references let those relative includes resolve.

local libvirt_dir = "/usr/share/libvirt/schemas"
local has_libvirt = vim.fn.isdirectory(libvirt_dir) == 1

-- libvirt root element -> schema file. Covers every object type that has an
-- editable XML representation (virsh *-edit / *-define / *-create).
local root_schema = {
  domain = "domain.rng",
  domainsnapshot = "domainsnapshot.rng",
  domaincheckpoint = "domaincheckpoint.rng",
  network = "network.rng",
  networkport = "networkport.rng",
  pool = "storagepool.rng", -- virsh pool-edit
  volume = "storagevol.rng", -- virsh vol-... (dumpxml)
  interface = "interface.rng", -- virsh iface-edit
  filter = "nwfilter.rng", -- virsh nwfilter-edit (root element is <filter>)
  secret = "secret.rng", -- virsh secret-define
  device = "nodedev.rng", -- virsh nodedev-... (root element is <device>)
  capabilities = "capability.rng", -- virsh capabilities
  domainCapabilities = "domaincaps.rng", -- virsh domcapabilities
}

--- Return the first XML element name in a buffer (the root element), skipping
--- the <?xml?> prolog, <?xml-model?> PIs and <!-- comments -->.
---@param bufnr integer
---@return string|nil
local function detect_root(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
    -- `<` immediately followed by a letter => an element (prolog/PI/comment
    -- start with `<?` or `<!`, so their `%a` never sits right after `<`).
    local tag = line:match("^%s*<([%a][%w_%-]*)")
    if tag then
      return tag
    end
  end
  return nil
end

--- Detect the libvirt object type of `bufnr` and, if recognised, register a
--- per-buffer fileAssociation with the lemminx `client` so it validates against
--- the correct RelaxNG schema.
---@param client vim.lsp.Client
---@param bufnr integer
local function bind_libvirt_schema(client, bufnr)
  local rng = root_schema[detect_root(bufnr) or ""]
  if not rng then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return
  end
  -- lemminx matches fileAssociations against the file name; the virsh temp
  -- basename (virshXXXXXX.xml) is unique enough to key on.
  local pattern = vim.fs.basename(name)

  local settings = client.settings or (client.config and client.config.settings) or {}
  settings.xml = settings.xml or {}
  local associations = settings.xml.fileAssociations or {}

  -- Drop any stale association for this file, then add the current one.
  for i = #associations, 1, -1 do
    if associations[i].pattern == pattern then
      table.remove(associations, i)
    end
  end
  table.insert(associations, { systemId = libvirt_dir .. "/" .. rng, pattern = pattern })

  settings.xml.fileAssociations = associations
  client.settings = settings
  client:notify("workspace/didChangeConfiguration", { settings = settings })
end

if has_libvirt then
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("evgenkot_lemminx_libvirt", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "lemminx" then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(args.buf) then
            bind_libvirt_schema(client, args.buf)
          end
        end)
      end
    end,
  })
end

return {
  settings = {
    xml = {
      validation = { enabled = true },
      -- libvirt files are bound by content in the LspAttach hook above.
    },
  },
}
