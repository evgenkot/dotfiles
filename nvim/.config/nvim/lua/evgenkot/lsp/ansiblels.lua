local has_ansible_lint = vim.fn.executable("ansible-lint") == 1

return {
    filetypes = { "yaml.ansible" },
    root_markers = { { "ansible.cfg", ".ansible-lint", "roles", "inventory", "inventories", "group_vars", "host_vars" } },
    get_language_id = function()
        return "yaml.ansible"
    end,
    settings = {
        ansible = {
            python = {
                interpreterPath = "python",
            },
            ansible = {
                path = "ansible",
            },
            executionEnvironment = {
                enabled = false,
            },
            validation = {
                enabled = true,
                lint = {
                    enabled = has_ansible_lint,
                    path = "ansible-lint",
                },
            },
        },
    },
}
