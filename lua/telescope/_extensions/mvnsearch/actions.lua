local state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod

local util = require("telescope._extensions.mvnsearch.util")
local inserters = require("telescope._extensions.mvnsearch.inserters")
local opts = require("telescope._extensions.mvnsearch.config").opts

local M = {}

local function detect_build_system()
    for _, inserter in pairs(inserters) do
        if util.file_exists(inserter.script_path) then
            return inserter, true
        end
    end
    return opts.preferred_build_system, false
end

M.yank = function(prompt_bufnr)
    local package = state.get_selected_entry().package
    vim.fn.setreg(opts.yank_register, detect_build_system().format(package))
    print("Dependency string yanked to register '" .. opts.yank_register .. "'")
end

M.insert_to_build_script = function(prompt_bufnr)
    local package = state.get_selected_entry().package
    local inserter, found = detect_build_system()
    if not found then
        print("Build script not found, fallback to yank")
        vim.fn.setreg(opts.yank_register, inserter.format(package))
        return
    end

    inserter.insert(package, opts)
end

return transform_mod(M)
