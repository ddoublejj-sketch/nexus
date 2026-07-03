--!strict

local process = require("@lune/process")

local QualityGate = require("./lib/QualityGate")

local results = QualityGate.runAll()
local passed = QualityGate.allPassed(results)

for _, result in results do
	print(
		("[%s] %s (%.2fs, exit %d)"):format(
			if result.ok then "PASS" else "FAIL",
			result.label,
			result.duration,
			result.code
		)
	)

	if not result.ok then
		if result.stdout ~= "" then
			print(result.stdout)
		end
		if result.stderr ~= "" then
			print(result.stderr)
		end
	end
end

print(if passed then "Quality gate PASS" else "Quality gate FAIL")

if not passed then
	process.exit(1)
end
