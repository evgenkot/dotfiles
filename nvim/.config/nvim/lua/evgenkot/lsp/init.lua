local servers = {
    "helm_ls",
    "yamlls",
    "lua_ls",
    "rust_analyzer",
}

for _, server in ipairs(servers) do
    local config = require("evgenkot.lsp." .. server)
    vim.lsp.config(server, config)
end
