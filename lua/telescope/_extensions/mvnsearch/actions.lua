local state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod

local util = require("telescope._extensions.mvnsearch.util")
local inserters = require("telescope._extensions.mvnsearch.inserters")
local config = require("telescope._extensions.mvnsearch.config")

local M = {}

local function detect_build_system()
    for _, inserter in pairs(inserters) do
        if util.file_exists(inserter.script_path) then
            return inserter, true
        end
    end
    return config.preferred_build_system, false
end

M.yank = function(prompt_bufnr)
    local package = state.get_selected_entry().package
    vim.fn.setreg(config.yank_register, detect_build_system().format(package))
    print("Dependency string yanked to register '" .. config.yank_register .. "'")
end

M.insert_to_build_script = function(prompt_bufnr)
    local package = state.get_selected_entry().package
    local inserter, found = detect_build_system()
    if not found then
        print("Build script not found, fallback to yank")
        vim.fn.setreg(config.yank_register, inserter.format(package))
        return
    end

    inserter.insert(package, config)
end

M.next_page = function(prompt_bufnr)
    local picker = state.get_current_picker(prompt_bufnr)
    local pager = vim.b[prompt_bufnr].pager
    pager:next()
    local response = util.make_query(pager)
    if not response then
        print("Request failed")
        return
    end
    vim.b[prompt_bufnr].pager = pager
    print("Page", pager.page + 1, "of", pager:max_page() + 1)
    picker:refresh(util.maven_finder(response))
end

M.prev_page = function(prompt_bufnr)
    local picker = state.get_current_picker(prompt_bufnr)
    local pager = vim.b[prompt_bufnr].pager
    pager:prev()
    local response = util.make_query(pager)
    if not response then
        print("Request failed")
        return
    end
    vim.b[prompt_bufnr].pager = pager
    print("Page", pager.page + 1, "of", pager:max_page() + 1)
    picker:refresh(util.maven_finder(response))
end

M.new_query = function(prompt_bufnr)
    local picker = state.get_current_picker(prompt_bufnr)
    local pager = vim.b[prompt_bufnr].pager
    if picker:_get_prompt() == "" then
        return
    end
    pager.query = picker:_get_prompt()
    pager.page = 0
    local response = util.make_query(pager)
    if not response then
        print("Request failed")
        return
    end
    vim.b[prompt_bufnr].pager = pager
    print(string.format("Search query changed to %s. Got %d results", pager.query, pager.total))
    picker:refresh(util.maven_finder(response), {})
end

return transform_mod(M)
