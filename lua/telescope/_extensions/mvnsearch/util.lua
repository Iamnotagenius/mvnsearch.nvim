local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

local curl = require('plenary.curl')
local xml2lua = require("xml2lua")
local xml_handler = require("xmlhandler.tree")

local config = require("telescope._extensions.mvnsearch.config")
local pagers = require("telescope._extensions.mvnsearch.pagers")

local api_endpoint = "https://search.maven.org/solrsearch/select"

local function file_exists(filepath)
    local f = io.open(filepath)
    return f ~= nil and io.close(f)
end

local function parse_xml_response(xml)
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
    return packages, tonumber(maven_handler.root.response.result._attr.numFound)
end

local function make_query(query, rows, start)
    start = start or 0
    local response = curl.get(api_endpoint, {
        query = {
            q = query,
            rows = tostring(rows),
            start = tostring(start),
            wt = "xml"
        },
    })
    if response.status ~= 200 then
        error("Request failed with status " .. response.status .. ": " .. response.body)
        return
    end
    return parse_xml_response(response.body)
end

local function make_query_async(query, rows, start, callback)
    start = start or 0
    curl.get(api_endpoint, {
        query = {
            q = query,
            rows = tostring(rows),
            start = tostring(start),
            wt = "xml"
        },
        callback = function(response)
            if response.status ~= 200 then
                error("Request failed with status " .. response.status .. ": " .. response.body)
                return
            end
            local packages, total = parse_xml_response(response.body)
            callback(packages, total)
        end
    })
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

local function maven_picker(opts, packages, total)
    return pickers.new(opts, {
        results_title = "Maven Central Search",
        sorter = telescope_config.generic_sorter(opts),
        finder = maven_finder(packages),
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
            pagers.new(opts.query, opts.rows, total, prompt_bufnr)
            return true
        end,
    })
end

return {
    file_exists = file_exists,
    make_query = make_query,
    make_query_async = make_query_async,
    new_pager = new_pager,
    maven_picker = maven_picker,
    maven_finder = maven_finder
}
