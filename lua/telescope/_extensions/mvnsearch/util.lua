local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

local http_request = require("http.request")
local http_util = require("http.util")
local xml2lua = require("xml2lua")
local xml_handler = require("xmlhandler.tree")

local config = require("telescope._extensions.mvnsearch.config")

local api_endpoint = "https://search.maven.org/solrsearch/select"

local function file_exists(filepath)
    local f = io.open(filepath)
    return f ~= nil and io.close(f)
end

local function make_query(pager)
    local url = api_endpoint .. '?' .. http_util.dict_to_query {
        q = pager.query,
        rows = tostring(pager.rows),
        start = tostring(pager:get_start()),
        wt = "xml"
    }
    local headers, stream = assert(http_request.new_from_uri(url):go())
    local xml = assert(stream:get_body_as_string())
    if headers:get(":status") ~= "200" then
        print("Request failed: " .. xml)
        return
    end
    local maven_handler = xml_handler:new()
    local maven_parser = xml2lua.parser(maven_handler)
    maven_parser:parse(xml)
    local packages = {}
    for _, doc in pairs(maven_handler.root.response.result.doc) do
        local package = {}
        for _, str in pairs(doc.str) do
            package[str._attr.name] = str[1]
        end
        package[doc.long._attr.name] = tonumber(doc.long[1])
        package[doc.int._attr.name] = tonumber(doc.int[1])
        table.insert(packages, package)
    end
    pager.total = maven_handler.root.response.result._attr.numFound
    return packages
end

local displayer = entry_display.create {
    separator = " ",
    items = {
        { width = 48 },
        { width = 36 },
        { width = 20 },
        { remaining = true }
    }
}

local function maven_finder(packages)
    return finders.new_table {
        results = packages,
        entry_maker = function(package)
            return {
                ordinal = package.id,
                display = function(entry)
                    return displayer {
                        entry.package.g,
                        entry.package.a,
                        entry.package.latestVersion,
                        entry.package.versionCount
                    }
                end,
                package = package
            }
        end
    }
end

local function new_pager(query, rows)
    return {
        query = query,
        rows = rows,
        page = 0,
        total = 0,
        get_start = function(self)
            return self.page * self.rows
        end,
        next = function(self)
            if self.page == self:max_page() then
                self.page = 0
                return
            end
            self.page = self.page + 1
        end,
        prev = function(self)
            if self.page == 0 then
                self.page = self:max_page()
                return
            end
            self.page = self.page - 1
        end,
        max_page = function(self)
            return math.ceil(self.total / self.rows) - 1
        end,
    }
end

local function maven_picker(opts, pager)
    local response = make_query(pager)
    if not response then
        return
    end
    return pickers.new(opts, {
        results_title = "Maven Central Search",
        sorter = telescope_config.generic_sorter(opts),
        finder = maven_finder(response),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                config.default_action(prompt_bufnr)
            end)
            for mode, mappings in pairs(config.mappings) do
                for mapping, action in pairs(mappings) do
                    map(mode, mapping, action)
                end
            end
            vim.b[prompt_bufnr].pager = pager
            return true
        end,
    })
end

return {
    file_exists = file_exists,
    make_query = make_query,
    new_pager = new_pager,
    maven_picker = maven_picker,
    maven_finder = maven_finder
}
