if _G.loaded_macroedit then
  return
end
_G.loaded_macroedit = 1

M = {_state = {}}
local function debug(...) vim.notify(vim.inspect(...)) end

local buf_in, buf_out, buf_macro
local win_in, win_out, win_macro

M._state.macroedit_buffers = {}
M._state.macroedit_windows = {}
M._state.is_open = false

-- check that register is one of these
local ALL_REGISTERS = { "*", "+", "\"", "-", "/", "_", "=", "#", "%", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }
local current_window = 0
local api = vim.api

-- TODO dosent currently work, need to investigate
local function set_mappings()
	for buf, _ in pairs(M._state.macroedit_buffers) do
		for k,v in pairs(M.mappings) do
			api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"setup/macroedit".'..v..'<cr>', {
				nowait = true, noremap = true, silent = true
			})
		end
	end
end

function M.setup(usr_config)
	M.config = {
		default_macro_register = 'q',
		default_selection_register = '"',
		default_to_visual_selection = true,
		default_mappings = { q = 'macroedit_close()', },
	}
	if usr_config then
		M.config = vim.tbl_extend('force', M.config, usr_config)
	end

	set_mappings()
	return M
end

-- Get the contents of the register
local function get_register_contents(register_name)
	return vim.fn.getreg(register_name, 1, nil)
end

-- check if the register contains anything, if not, return false, nil
local function get_register_contents_opt(register_name)
	local opt_value = get_register_contents(register_name)

	local is_empty = #opt_value == 0

	if not is_empty then
		is_empty = #(opt_value:match("^%s*(.-)%s*$")) == 0
	end

	if is_empty then return false, nil end
	return true, opt_value
end

-- set the contents of the register
local function set_register_contents(register_name, contents)
	return vim.fn.setreg(register_name, contents)
end

local function split (inputstr)
	local sep = "\n"
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

local function unsplit(tb)
	local s = ""
	if #tb == 1 then
		return table.remove(tb)
	end
	for _, v in pairs(tb) do
		s = s..v.."\n"
	end
	return s
end

-- close all windows and delete all temporary buffers
local function close_all_windows()
	for _, win in ipairs(M._state.macroedit_windows) do
		if api.nvim_win_is_valid(win) then
			api.nvim_win_close(win, false)
		end
	end

	-- for _, buf in ipairs(macroedit_buffers) do
	-- 	if win then api.nvim_buf_delete(buf, {force = true}) end
	-- end
end

-- create a bordered window around the params
-- TODO implement
local function get_selected_region()
end

local function set_buffer_opts(buf, selection_lines)
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
	api.nvim_buf_set_lines(buf, 0, -1, false, selection_lines)
end

-- execute a macro
--- @param macro_register string #Macro string to be executed
local function execute_macro(macro_register)
	local macro = get_register_contents(macro_register)
	local keys = vim.api.nvim_replace_termcodes(macro, true, false, true)
	api.nvim_feedkeys(keys, 'x', false)
end

local function execute_macro_in_window(macro_register, window)
	local cursor_pos = {1,0}
	api.nvim_set_current_win(window)
	api.nvim_win_set_cursor(window, cursor_pos)
	execute_macro(macro_register)
end

-- couldnt get vim.api.nvim_win_call to work so this is the alternative until I understand it
local function wrap_window_call(fn)
	local save_window = api.nvim_get_current_win()
	local save_buffer = api.nvim_get_current_buf()
	local save_cursor = api.nvim_win_get_cursor(current_window)
	fn()
	api.nvim_set_current_win(save_window)
	api.nvim_set_current_buf(save_buffer)
	api.nvim_win_set_cursor(save_window, save_cursor)
end

local function run_macro_callback(clean_buf, dirty_buf, macro_buf, macro_register)
	-- save the macro from the  macro buffer
	local macro = unsplit(api.nvim_buf_get_lines(macro_buf, 0, -1, false))
	set_register_contents(macro_register, macro)

	-- get the text from the clean buffer
	local lines = api.nvim_buf_get_lines(clean_buf, 0, -1, false)

	-- load the dirty buffer with the clean lines
	api.nvim_buf_set_lines(dirty_buf, 0, -1, false, lines)

	-- run the macro on the dirty buffer
	wrap_window_call(function() execute_macro_in_window(macro_register, win_out) end)
end

local function launch_windows(macro_register, selection)
	buf_in = api.nvim_create_buf(false, true)
	buf_out = api.nvim_create_buf(false, true)
	buf_macro = api.nvim_create_buf(false, true)

	-- set the filetype so there is highlighting in the window
	-- TODO see if there is a smarter way of doing this
	-- TODO see what other options may need to get set
	-- TODO buf_out should not be editable
	local filetype = api.nvim_buf_get_option(0, 'filetype')
	api.nvim_buf_set_option(buf_in, "filetype", filetype)
	api.nvim_buf_set_option(buf_out, "filetype", filetype)
	set_buffer_opts(buf_macro, split(get_register_contents(macro_register)))
	set_buffer_opts(buf_in, selection)
	set_buffer_opts(buf_out, selection)

	-- inputsave() might be useful here for TextChangedI
	local edit_events = {"InsertLeave", "TextChanged"} --"TextChangedI",
	local close_events = {"BufDelete", "WinClosed"} -- "BufLeave"
	api.nvim_create_augroup('MacroEdit', {clear = true})
	api.nvim_create_autocmd(edit_events, {
		group = "MacroEdit",
		buffer = buf_macro,
		callback = function ()
			run_macro_callback(buf_in, buf_out, buf_macro, macro_register)
		end,
	})

	-- if one window is closed, the others are as well
	api.nvim_create_autocmd(close_events, {
		group = "MacroEdit",
		buffer = buf_macro,
		callback = function () M.macroedit_close() end,
	})
	api.nvim_create_autocmd(close_events, {
		group = "MacroEdit",
		buffer = buf_in,
		callback = function () M.macroedit_close() end,
	})
	api.nvim_create_autocmd(close_events, {
		group = "MacroEdit",
		buffer = buf_out,
		callback = function () M.macroedit_close() end,
	})

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate macro window dimensions and position
  local macro_win_height = 1
  local macro_win_width = math.ceil(width * 0.3)
	local row = 1
	local col = math.ceil((width*0.5)-(macro_win_width/2))

  local win_height = #selection + math.ceil(#selection * 0.4)
	if win_height > math.ceil(height*0.4) then
		win_height = math.ceil(height*0.4)
	elseif win_height < 2 then
		win_height = 2
	end

  local win_width = math.ceil(width * 0.3)

  local macro_opts = {
    style = "minimal",
    relative = "editor",
    width = macro_win_width,
    height = macro_win_height,
    row = row,
    col = col,
		border = "rounded",
  }
	-- make window for macro editing
  win_macro = api.nvim_open_win(buf_macro, true, macro_opts)

	-- 2nd window should be directly underneath the macro window
	-- relative = "win" is having weird movement issues
  local view_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = macro_win_height+3,
    col = col,
		border = "rounded",
		focusable = false,
  }
  win_in = api.nvim_open_win(buf_in, false, view_opts)

	-- 3rd window should be directly underneath the 2nd window
	-- view_opts.win = win_in
	view_opts.row = view_opts.row + win_height +2
  win_out = api.nvim_open_win(buf_out, false, view_opts)
	M._state.macroedit_buffers = {buf_in, buf_out, buf_macro}
  M._state.macroedit_windows = {win_in, win_out, win_macro}
end

-- get the text selection as needed and launch the editing windows
local function launch(macro_register, selection)
	-- get the text selection
	if M.config.default_to_visual_selection then
		selection = get_selected_region()
	elseif not selection and M.config.default_selection_register then
		selection = get_register_contents(M.config.default_selection_register)
	end

	if not selection then
		selection = ""
	end
	debug(selection)
	-- launch the windows
	launch_windows(macro_register, split(selection))
end

-- function M.switch_to_macro_window()
-- 	if win_macro then api.nvim_set_current_win(win_macro) end
-- end

-- function M.switch_to_in_window()
-- 	if win_in then api.nvim_set_current_win(win_in) end
-- end

-- function M.switch_to_out_window()
-- 	if win_out then api.nvim_set_current_win(win_out) end
-- end


--- Open the MacroEdit windows
function M.macroedit_open(opts)
	if M._state.is_open then return end

	local reg = M.config.default_macro_register
	if opts and opts.fargs[0] then reg = opts.fargs[0] end
	launch(reg)
	M._state.is_open = true
end

--- Close the MacroEdit windows
function M.macroedit_close()
	if not M._state.is_open then return end
	close_all_windows()
	M._state.is_open = false
end

--- Toggle the MacroEdit windows open or closed
function M.macroedit_toggle(opts)
	if M._state.is_open then
		M.macroedit_close()
	else
		M.macroedit_open(opts)
	end
end

api.nvim_create_user_command('MacroEditOpen',
	function(opts) M.macroedit_open(opts) end,
	{desc = '', nargs="*", range=true})
api.nvim_create_user_command('MacroEditClose',
	function() M.macroedit_close() end,
	{desc = ''})
api.nvim_create_user_command('MacroEditToggle',
	function(opts) M.macroedit_toggle(opts) end,
	{desc = '', nargs="*"})

vim.api.nvim_set_keymap('', "mg", '<CMD>lua test()<CR>', {noremap = true})

return M
