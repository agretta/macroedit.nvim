-- TODO remove the debug logger
_P = function(v)
  print(vim.inspect(v))
  vim.notify(vim.inspect(v))
  return v
end

if _G.loaded_macroedit then return end
_G.loaded_macroedit = 1

local M = {
	_state = {
		macroedit_buffers = {},
		macroedit_windows = {},
		is_open = false,
	},
	config = {
		default_launch_mode = 'current',
		default_macro_register = 'q',
		default_mappings = {
			q = 'macroedit_close()',
		},
	}
}

local utils = require("macroedit.utils")
local ui = require("macroedit.ui")
local api = vim.api

-- adds a table of keybindings to a list of buffers
local function set_mappings(buffers)
	for _, buf in ipairs(buffers) do
		for k,v in pairs(M.config.default_mappings) do
			api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"macroedit".'..v..'<cr>', {noremap = true, silent = true, nowait = true})
		end
	end
end

function M.setup(usr_config)
	if usr_config then
		M.config = vim.tbl_extend('force', M.config, usr_config)
	end

	return M
end

-- close all windows and delete all temporary buffers
local function close_all_windows()
	for _, win in ipairs(M._state.macroedit_windows) do
		ui.close_window(win)
	end
end

local function get_edit_buffer(content)
	local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(0, 'filetype', 'macro')

	-- insert content into the buffer
	api.nvim_buf_set_lines(buf, 0, -1, false, content)
	api.nvim_buf_set_name(buf, "Macro @???")

	return buf
end

-- Sends input keys to nvim from a register
--- @param macro_register string #register of macro to be executed
local function execute_macro(macro_register)
	local macro = utils.get_register_contents(macro_register)
	local keys = vim.api.nvim_replace_termcodes(macro, true, false, true)
	-- _P(keys)
	api.nvim_feedkeys(keys, 'x', false)
end

-- local function execute_macro_by_key(macro_register)
-- 	local macro = utils.get_register_contents(macro_register)
-- 	local keys = vim.api.nvim_replace_termcodes(macro, true, false, true)
-- 	keys:gsub(".", function(c)
-- 		_P(c)
-- 		vim.fn.wait(10, function() end)
-- 		api.nvim_feedkeys(c, 'm', false)
-- 	end)
-- end

-- run a macro in a window/buffer
local function run_macro(macro_buf, macro_register, opts)

	-- save the macro from the macro buffer
	local macro = utils.unsplit(api.nvim_buf_get_lines(macro_buf, 0, -1, false))

	-- update the register with the edited macro
	utils.set_register_contents(macro_register, macro)

	-- reset the target buffer
	api.nvim_buf_set_lines(opts.target_buffer, 0, -1, false, opts.current_text)

	-- execute the macro in the target window/buffer
	vim.api.nvim_win_call(opts.target_window,
		function()
			api.nvim_buf_call(opts.target_buffer,
				function()
					api.nvim_win_set_cursor(0, opts.cursor_pos)
					execute_macro(macro_register)
				end)
		end)

end

-- Add editing text autocmds to the buffer
local function add_edit_events(buf, register, opts)
	local edit_events = {"InsertLeave", "TextChanged"} -- , "TextChangedI"}
	api.nvim_create_autocmd(edit_events, {
		group = "MacroEdit",
		buffer = buf,
		callback = function ()
			run_macro(buf, register, opts)
		end,
	})
end

-- Add autocmds for when the buffer is exited
local function add_close_events(buf)
	local close_events = {"BufDelete", "WinClosed"} -- "BufLeave"
	api.nvim_create_autocmd(close_events, {
		group = "MacroEdit",
		buffer = buf,
		callback = function () M.macroedit_close() end,
	})
end

-- Add autocmds to save macro register contents on edit
local function add_save_events(buf, register)
	local edit_events = {"InsertLeave", "TextChanged", "TextChangedI"}
	api.nvim_create_autocmd(edit_events, {
		group = "MacroEdit",
		buffer = buf,
		callback = function ()
			utils.set_register_contents(register, utils.unsplit(api.nvim_buf_get_lines(buf, 0, -1, false)))
		end,
	})
end

local function apply_scratch_opts(buf)
	-- set the filetype so there is highlighting in the window
	-- TODO see if there is a smarter way of doing this
	-- TODO see what other options may need to get set
	-- TODO buf_out should not be editable
	local filetype = api.nvim_buf_get_option(0, 'filetype')
	api.nvim_buf_set_option(buf, "filetype", filetype)
	-- api.nvim_buf_set_option(buf, "modifiable", false)
end

--- a simple floating window to edit the macro that outputs changes to a buffer
--- @return windows
--- @return buffers
local function launch_current(mregister)
	local current_window = api.nvim_get_current_win()
	local current_buffer = api.nvim_get_current_buf()
	local current_cursor = api.nvim_win_get_cursor(current_window)

	-- get a buffer with the contents of a macro register
	local buf = get_edit_buffer(utils.split(utils.get_register_contents(mregister)))

  -- get dimensions of nvim
  local nvim_width = api.nvim_get_option("columns")

  -- calculate macro window dimensions and position
  local macro_win_height = 1
  local macro_win_width = math.ceil(nvim_width * 0.3)
	local row = ui.get_vcenter(-1, macro_win_height)
	local col = ui.get_hcenter(-1, macro_win_width)

  local opts = {
    width = macro_win_width,
    height = macro_win_height,
    row = row,
    col = col,
		focusable = true,
  }
  local win = ui.open_window(buf, true, opts)

	add_edit_events(buf, mregister, {
			target_window = current_window,
			target_buffer = current_buffer,
			cursor_pos = current_cursor,
			current_text = api.nvim_buf_get_lines(current_buffer, 0, -1, false)
		})
	add_close_events(buf)

	return {buf}, {win}
end

--- a simple floating window to edit a macro register
--- @return windows
--- @return buffers
local function launch_minimal(mregister)

	-- get a buffer containing the the macro register
	local buf = get_edit_buffer(utils.split(utils.get_register_contents(mregister)))

  -- get dimensions of nvim
  local nvim_width = api.nvim_get_option("columns")

  -- calculate macro window dimensions and position
  local macro_win_height = 1
  local macro_win_width = math.ceil(nvim_width * 0.3)
	local row = ui.get_vcenter(-1, macro_win_height)
	local col = ui.get_hcenter(-1, macro_win_width)

  local opts = {
    width = macro_win_width,
    height = macro_win_height,
    row = row,
    col = col,
		focusable = true,
  }
  local win = ui.open_window(buf, true, opts)

	add_save_events(buf, mregister)
	add_close_events(buf)

	return {buf}, {win}
end

-- get the text selection as needed and launch the editing windows
local function launch(mregister, selection)
	if not selection then selection = "" end

	api.nvim_create_augroup('MacroEdit', {clear = true})

	local buffers = {}
	local windows = {}
	if M.config.default_launch_mode == "minimal" then
		buffers, windows = launch_minimal(mregister)
	elseif M.config.default_launch_mode == "current" then
		buffers, windows = launch_current(mregister)
	end

	M._state.macroedit_buffers = buffers
  M._state.macroedit_windows = windows

	set_mappings(buffers)
end

--- Open the MacroEdit windows
function M.macroedit_open(opts)
	if M._state.is_open then return end

	local reg = M.config.default_macro_register
	if opts and opts.fargs and #opts.fargs > 0 then
		-- TODO verify is register here
		reg, _ = unpack(opts.fargs)

		-- if called with @ as an argument, set it to the " register
		if reg == '@' then reg = '"' end
	end
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
	{desc = '', nargs="*", range = true})
api.nvim_create_user_command('MacroEditClose',
	function() M.macroedit_close() end,
	{desc = ''})
api.nvim_create_user_command('MacroEditToggle',
	function(opts) M.macroedit_toggle(opts) end,
	{desc = '', nargs="*", range = true})

-- TODO use get_char to get the mapping c@ working
-- https://stackoverflow.com/questions/69191079/how-to-do-mark-like-mapping-in-vim
local opts = {noremap = true, silent = false}
-- api.nvim_set_keymap('n', '<Plug>MacroEditReg', [[<CMD>lua require("macroedit").macroedit_open(vim.cmd"getchar()")<CR>", {noremap = true}]], {})
-- api.nvim_set_keymap('n', 'c@', "<Plug>MacroEditReg <CR>", {})
for _, value in ipairs(utils.get_regs()) do
	api.nvim_set_keymap('n', 'c@'..value, "<CMD>MacroEditOpen "..value.."<CR>", opts)
end

api.nvim_set_keymap('n', '<leader>mo', "<CMD>MacroEditOpen<CR>", opts)
api.nvim_set_keymap('n', '<leader>mc', "<CMD>MacroEditClose<CR>", opts)
api.nvim_set_keymap('n', '<leader>mt', "<CMD>MacroEditToggle<CR>", opts)

return M
