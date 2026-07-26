vim.opt.runtimepath:prepend(vim.fn.getcwd())
package.path = "tests/?.lua;" .. package.path

local tests = require("model_endpoints_spec")
local failures = {}

for _, test in ipairs(tests) do
	local ok, err = xpcall(test.run, debug.traceback)
	if ok then
		print("PASS " .. test.name)
	else
		table.insert(failures, "FAIL " .. test.name .. "\n" .. err)
	end
end

if #failures > 0 then
	error(table.concat(failures, "\n\n"), 0)
end
