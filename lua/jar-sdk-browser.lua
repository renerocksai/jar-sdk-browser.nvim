local Job = require("plenary.job")
local debug_utils = require("plenary.debug_utils")

local M = {}

local sourced_file = debug_utils.sourced_filepath()
M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h")

M._process_class_job = function(jarfile, class, outfile, progress, final_fn)
	local compiled_from = "Compiled from"

	return Job:new({
		command = M.javap_bin,
		args = { "-public", "-constants", "-classpath", jarfile, class },
		on_start = function()
			print("Processing class " .. class .. progress)
		end,
		on_exit = function(j, _)
			for _, line in pairs(j:result()) do
				if line:sub(1, #compiled_from) == compiled_from then
					line = "\n"
				end
				outfile:write(line .. "\n")
			end
			if final_fn ~= nil then
				final_fn()
			end
		end,
		on_stderr = function(err, data, _)
			print("error:", tostring(err), data)
		end,
	})
end

M._list_classes = function(jarfile)
	local classes = {}
	jarfile = vim.fn.expand(jarfile)
	print("adding jar", jarfile, "...")

	local class = ".class"

	local j = Job:new({
		command = M.jar_bin,
		args = { "-tf", jarfile },
		on_exit = function(j, _)
			for _, line in pairs(j:result()) do
				if line:sub(-#class) == class then
					line = line:sub(1, -#class - 1)
					line = line:gsub("/", ".")
					classes[#classes + 1] = line
				end
			end
		end,
		on_stderr = function(err, data, _)
			print("error:", tostring(err), data)
		end,
	})
	j:sync() -- on_exit handler does the processing
	vim.cmd([[redraw!]])

	return classes
end

M.add_jar = function(jar, opts)
	opts = opts or {}
	local jobs = {}

	local outfiln = M.sdk_folder .. "/" .. vim.fn.fnamemodify(jar, ":t") .. ".java"
	local outfile = io.open(outfiln, "a")
	outfile:write("\n")

	local function finalize()
		outfile:close()
		print("Finished " .. jar)
	end

	local classes = M._list_classes(jar)
	if classes ~= nil then
		for i, classname in ipairs(classes) do
			local finalizer = nil
			if i == #classes then
				finalizer = finalize
			end
			jobs[i] = M._process_class_job(jar, classname, outfile, " (" .. i .. " / " .. #classes .. ")", finalizer)
		end
	end

	-- now iterate over all jobs and chain them together
	for i, j in ipairs(jobs) do
		if i > 1 then
			jobs[i - 1]:and_then_wrap(j)
		end
	end

	if #jobs > 0 then
		jobs[1]:start()
	end
end

M.setup = function(opts)
	opts = opts or {}
	M.sdk_folder = opts.sdk_folder or M.base_directory .. "/" .. "sdks"
	M.javap_bin = opts.javap_bin or "javap"
	M.jar_bin = opts.jar_bin or "jar"
end

return M
