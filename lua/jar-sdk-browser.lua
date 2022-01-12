local Job = require("plenary.job")
local debug_utils = require("plenary.debug_utils")

local M = {}

local sourced_file = debug_utils.sourced_filepath()
M.base_directory = vim.fn.fnamemodify(sourced_file, ":h:h:h")

print(M.base_directory)

return M
