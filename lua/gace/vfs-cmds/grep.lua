local function GrepFile(node, query, results)
    return node:read():then_(function(str)

        -- Disgusting. TODO optimize
        for i,line in pairs(str:Split("\n")) do
            local findindex = string.find(line, query, _, true)

            if findindex then
                table.insert(results, {
                    path = node:path(),
                    row = i,
                    linestr = line
                })
            end
        end
    end)
end

local function GrepFolder(node, query, results)
    return node:listEntries():then_(function(entries)
        local promises = {}

        for _,e in pairs(entries) do
            if e:type() == "folder" then
                table.insert(promises, GrepFolder(e, query, results))
            elseif e:type() == "file" then
                table.insert(promises, GrepFile(e, query, results))
            end
        end

        return ATPromise(promises):all()
    end)
end

gace.RegisterCommand("grep", {
    name = "Grep",
    help = "Searches folder/file for a string",
    ipc = "cmd-grep",
    args = {
        {type = "string", name = "path"},
        {type = "string", name = "query"}
    },
    func = function(caller, path, query)
    	return gace.fs.resolve(gace.path.normalize(path)):then_(function(node)
			if not node:hasPermission(caller, gace.VFS.Permission.READ) then
				return error(gace.VFS.ErrorCode.ACCESS_DENIED)
			end

            local res = {}
    		if node:type() == "file" then
                return GrepFile(node, query, res):then_(function()
                    return res
                end)
    		elseif node:type() == "folder" then
                return GrepFolder(node, query, res):then_(function()
                    return res
                end)
            end

			return error(gace.VFS.ErrorCode.INVALID_TYPE)
    	end)
    end,
    func_ipc = function(caller, request, promise)
        promise:then_(function(res)
            request:CreateResponsePacket("cmd-grep", {results = res}):Send()
        end):catch(function(err)
            request:CreateResponsePacket("cmd-grep", {err = err}):Send()
        end)
    end,
    func_tostring = function(caller, promise)
        promise:then_(function(res)
            if #res == 0 then
                caller:GAce_Msg(gace.LOG_INFO, "No results!")
            end
            for _,v in pairs(res) do
                caller:GAce_Msg(gace.LOG_INFO, v.path, "@", v.row, ": ", v.linestr)
            end
        end):catch(function(err)
            caller:GAce_Msg(gace.LOG_ERROR, err)
        end)
    end
})
