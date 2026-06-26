local M = {}

local render_script = [[
import json
import pathlib
import sys

import jinja2
import yaml


class EmptyUndefined(jinja2.ChainableUndefined):
    def __bool__(self):
        return False

    def __iter__(self):
        return iter(())

    def __str__(self):
        return ""


def load_vars(path):
    if not path:
        return {}

    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    return data or {}


template_path = pathlib.Path(sys.argv[1]).resolve()
vars_path = sys.argv[2] if len(sys.argv) > 2 else None
env = jinja2.Environment(
    loader=jinja2.FileSystemLoader(str(template_path.parent)),
    undefined=EmptyUndefined,
    keep_trailing_newline=True,
)
env.filters.setdefault("to_json", json.dumps)
env.filters.setdefault("to_yaml", yaml.safe_dump)
env.filters.setdefault("to_nice_yaml", yaml.safe_dump)

template = env.get_template(template_path.name)
sys.stdout.write(template.render(**load_vars(vars_path)))
]]

local function strip_j2_suffix(path)
    return path:gsub("%.j2$", "")
end

local function detect_rendered_filetype(path)
    local name = vim.fn.fnamemodify(strip_j2_suffix(path), ":t")
    if name == "" then
        return nil
    end

    return vim.filetype.match({ filename = name })
end

function M.rendered_filetype(path)
    return detect_rendered_filetype(path) or "text"
end

function M.source_filetype(path)
    local filetype = detect_rendered_filetype(path)
    if filetype == "" or filetype == nil then
        return "jinja"
    end

    return "jinja." .. filetype
end

local function has_filetype(config, filetype)
    return type(config) == "table"
        and type(config.filetypes) == "table"
        and vim.tbl_contains(config.filetypes, filetype)
end

local function start_preview_lsps(buf, filetype, source_path)
    if not vim.lsp.config then
        return
    end

    local configs = vim.lsp.config._configs or vim.lsp.config
    local root_dir = vim.fs.root(source_path, { ".git" }) or vim.fn.getcwd()
    for name in pairs(configs) do
        local config = vim.lsp.config[name]
        if has_filetype(config, filetype) then
            local preview_config = vim.deepcopy(config)
            if type(preview_config.root_dir) ~= "string" then
                preview_config.root_dir = root_dir
            end
            pcall(vim.lsp.start, preview_config, { bufnr = buf })
        end
    end
end

function M.preview(vars_path)
    local source_path = vim.api.nvim_buf_get_name(0)
    if not source_path:match("%.j2$") then
        vim.notify("J2Preview: current buffer is not a .j2 template", vim.log.levels.WARN)
        return
    end

    local cmd = { "python3", "-", source_path }
    if vars_path and vars_path ~= "" then
        table.insert(cmd, vim.fn.expand(vars_path))
    end

    vim.system(cmd, { stdin = render_script, text = true }, function(result)
        vim.schedule(function()
            if result.code ~= 0 then
                vim.notify(result.stderr ~= "" and result.stderr or result.stdout, vim.log.levels.ERROR)
                return
            end

            local rendered_path = strip_j2_suffix(source_path)
            vim.cmd("vnew")

            local buf = vim.api.nvim_get_current_buf()
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].bufhidden = "wipe"
            vim.bo[buf].swapfile = false
            vim.api.nvim_buf_set_name(buf, rendered_path)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout, "\n", { plain = true }))
            vim.bo[buf].modified = false
            local filetype = M.rendered_filetype(source_path)
            vim.bo[buf].filetype = filetype
            start_preview_lsps(buf, filetype, source_path)
        end)
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("J2Preview", function(opts)
        M.preview(opts.args)
    end, {
        nargs = "?",
        complete = "file",
        desc = "Render current Jinja2 template into a preview buffer",
    })
end

return M
