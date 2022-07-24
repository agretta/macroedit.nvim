-- user interface module
-- handle creation/deletion/modification of windows

local M = {}

M.default_opts = {
	window = {
		border = "rounded",
		relative = "editor",
		focusable = false,
		style = "minimal",
	}
}

function M.set_default_opts(defaults)
	M.default_opts = vim.tbl_extend('force', M.default_opts, defaults)
end

function M.open_window(buf, enter, opts)
	opts = vim.tbl_extend('force', M.default_opts.window, opts)
  return vim.api.nvim_open_win(buf, enter, opts)
end

function M.close_window(win)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
end

-- calculate the col value to horizontally center a window
-- -1 uses nvim, ignoring any windows
function M.get_hcenter(win, win_width)
	if not win_width then win_width = 0 end
	local width
	if win == -1 then
		width = vim.api.nvim_get_option("columns")
	else
		width = vim.api.nvim_win_get_width(win)
	end
	return math.floor((width/2) - (win_width/2))
  -- local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
end

function M.get_vcenter(win, win_height)
	if not win_height then win_height = 0 end
	local height
	if win == -1 then
		height = vim.api.nvim_get_option("lines")
	else
		height = vim.api.nvim_win_get_height(win)
	end
	return math.floor((height/2) - (win_height/2))
  -- local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
end

return M
