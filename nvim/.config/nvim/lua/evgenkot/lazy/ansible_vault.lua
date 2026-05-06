return {
    "nvim-lua/plenary.nvim", -- required for some utilities
    config = function()
        -- Resolve the vault password file: prefer $ANSIBLE_VAULT_PASSWORD_FILE, fall back to ~/.vlt.
        -- Returns nil if the resolved file does not exist.
        local function get_password_file()
            local env = vim.env.ANSIBLE_VAULT_PASSWORD_FILE
            local path = (env and env ~= "") and env or "~/.vlt"
            path = vim.fn.expand(path)
            if vim.fn.filereadable(path) == 0 then
                vim.notify(
                    string.format("ansible-vault password file not found: %s", path),
                    vim.log.levels.ERROR
                )
                return nil
            end
            return path
        end

        -- Find the minimum common indent (ignoring blank lines)
        local function get_min_indent(lines)
            local min_indent = math.huge
            for _, line in ipairs(lines) do
                if line:match("%S") then
                    local indent = #line:match("^(%s*)")
                    if indent < min_indent then
                        min_indent = indent
                    end
                end
            end
            return min_indent == math.huge and 0 or min_indent
        end

        local function remove_indent(lines, indent)
            local result = {}
            for i, line in ipairs(lines) do
                result[i] = line:sub(indent + 1)
            end
            return result
        end

        local function add_indent(lines, indent)
            local prefix = string.rep(" ", indent)
            local result = {}
            for i, line in ipairs(lines) do
                result[i] = prefix .. line
            end
            return result
        end

        -- Run ansible-vault streaming via stdin/stdout, no tmp files
        local function vault_run_range(action)
            local password_file = get_password_file()
            if not password_file then
                return
            end

            local start_line = vim.fn.getpos("'<")[2]
            local end_line = vim.fn.getpos("'>")[2]

            local lines = vim.fn.getline(start_line, end_line)
            local indent = get_min_indent(lines)
            local stripped = remove_indent(lines, indent)

            local cmd = {
                "ansible-vault", action,
                "--vault-password-file", password_file,
                "--output", "-",
                "-",
            }
            local result = vim.fn.systemlist(cmd, stripped)

            if vim.v.shell_error ~= 0 then
                vim.notify(
                    string.format("ansible-vault %s failed: %s", action, table.concat(result, "\n")),
                    vim.log.levels.ERROR
                )
                return
            end

            if action == "encrypt" then
                table.insert(result, 1, "!vault |")
            end
            local final = add_indent(result, indent)

            vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, final)
        end

        vim.api.nvim_create_user_command("VaultEncryptRange", function()
            vault_run_range("encrypt")
        end, { range = true })
        vim.api.nvim_create_user_command("VaultDecryptRange", function()
            vault_run_range("decrypt")
        end, { range = true })

        vim.keymap.set("v", "<leader>ae", ":<C-u>VaultEncryptRange<CR>",
            { desc = "Ansible Vault Encrypt", silent = true })
        vim.keymap.set("v", "<leader>ad", ":<C-u>VaultDecryptRange<CR>",
            { desc = "Ansible Vault Decrypt", silent = true })
    end,
}
