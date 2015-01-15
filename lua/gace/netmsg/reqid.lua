gace.reqid = {}

local req_num = 0
function gace.reqid.generate()
	req_num = req_num + 1
	return math.floor(CurTime()) .. "_" .. req_num
end

function gace.reqid.validate(reqid)
    return type(reqid) == "string" and reqid ~= ""
end
