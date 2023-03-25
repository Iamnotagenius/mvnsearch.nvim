local state = require("telescope.actions.state")
local transform_mod = require("telescope.actions.mt").transform_mod

local util = require("telescope._extensions.mvnsearch.util")
local inserters = require("telescope._extensions.mvnsearch.inserters")
local config = require("telescope._extensions.mvnsearch.config")
local pagers = require("telescope._extensions.mvnsearch.pagers")

local M = {}

local function detect_build_system()
    for _, inserter in pairs(inserters) do
        if util.file_exists(inserter.script_path) then
            return inserter, true
        end
    end
    return config.preferred_build_system, false
end

M.yank = function()
    local package = state.get_selected_entry().package
    vim.fn.setreg(config.yank_register, detect_build_system().format(package))
    print("Dependency string yanked to register '" .. config.yank_register .. "'")
end

M.insert_to_build_script = function()
    local package = state.get_selected_entry().package
    local inserter, found = detect_build_system()
    if not found then
        print("Build script not found, fallback to yank")
        vim.fn.setreg(config.yank_register, inserter.format(package))
        return
    end

    inserter.insert(package, config)
end

local function switch_page(prompt_bufnr, switcher)
    local picker = state.get_current_picker(prompt_bufnr)
    local pager = pagers.get_from_buffer(prompt_bufnr)
    switcher(pager)
    util.make_query_async(pager.query, pager.rows, pager:get_start(), function(packages)
        print("Page", pager.page + 1, "of", pager:max_page() + 1)
        picker:refresh(util.maven_finder(packages))
    end)
end

M.next_page = function(prompt_bufnr)
    switch_page(prompt_bufnr, function(pager)
        pager:next()
    end)
end

M.prev_page = function(prompt_bufnr)
    switch_page(prompt_bufnr, function(pager)
        pager:prev()
    end)
end

M.new_query = function(prompt_bufnr)
    local picker = state.get_current_picker(prompt_bufnr)
    local pager = pagers.get_from_buffer(prompt_bufnr)
    if picker:_get_prompt() == "" then
        return
    end
    pager.query = picker:_get_prompt()
    pager.page = 0
    util.make_query_async(pager.query, pager.rows, pager:get_start(), function(packages, total)
        pager.total = total
        print(string.format("Search query changed to %s. Got %d results (%d pages).",
            pager.query,
            pager.total,
            pager:max_page() + 1))
        picker:refresh(util.maven_finder(packages))
    end)
end

return transform_mod(M)
