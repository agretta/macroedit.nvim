local M = {}

M._ALL_REGISTERS = { "*", "+", '"', "\"", "-", "/", "_", "=", "#", "%", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }

-- return a table of all registers
function M.get_regs()
	return vim.tbl_extend('keep', M._ALL_REGISTERS, {"@"})
end

-- check if a string is the name of a register
-- @param reg
function M.is_register(reg)
	return vim.tbl_contains(M._ALL_REGISTERS, reg)
end

-- Gets the contents of a register
-- @param name
function M.get_register_contents(name)
	return vim.fn.getreg(name, 1, nil)
end

-- check if the register contains anything, if not, return false, nil
function M.get_register_contents_opt(register_name)
	local opt_value = M.get_register_contents(register_name)

	local is_empty = #opt_value == 0

	if not is_empty then
		is_empty = #(opt_value:match("^%s*(.-)%s*$")) == 0
	end

	if is_empty then return false, nil end
	return true, opt_value
end

-- set the contents of the register
function M.set_register_contents(register_name, contents)
	return vim.fn.setreg(register_name, contents)
end


function M.split(inputstr)
	local sep = "\n"
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function M.unsplit(tb)
	local s = ""
	if #tb == 1 then
		return table.remove(tb)
	end
	for _, v in pairs(tb) do
		s = s..v.."\n"
	end
	return s
end

return M
