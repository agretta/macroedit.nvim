# macroedit.nvim

A neovim plugin for editing and visualizing macros.
Edit macros in a separate window and see how they affect the file currently being edited.

My first foray into lua and making plugins for neovim, this is a learning experience for me and I make no promises of future features/maintenance.

## Alternatives
If you just need to edit the occasional macro and don't need the visualizing portion of this plugin, macros can be edited natively without needing to be re-recorded. For example, assuming the macro register is `m`:

### Editing macros

#### Command Line
1. Type `:let @m=<C-R><C-R>m'`
2. Edit the text as desired
3. Append an apostrophe `'` to finish the command and press Enter

#### In a buffer
1. `"mp` to paste the contents of the macro register into a buffer
2. edit the text as required
3. `"myy` to select the modified macro and yank it back to the `m` register

### Visualizing macros
1. `:reg m` will show the contents of register m

## Features

| Command | Description | Notes |
|-|-|-|
| `MacroEditOpen *register*` | Open the MacroEdit windows | - |
| `MacroEditClose` | Close the MacroEdit windows | - |
| `MacroEditToggle *register*` | Toggle open/closed the MacroEdit windows| - |

## Requirements
* Neovim >=0.5.0

## Installation

**Vim-Plug**
```
Plug 'agretta/macroedit.nvim'
```
**Packer**
```
use 'agretta/macroedit.nvim'
```

## Configuration
**macroedit.nvim** comes with the following defaults

```
require("macroedit").setup({
	default_launch_mode = 'current',
	default_macro_register = 'q',
	default_mappings = {
		q = 'macroedit_close()',
	},
	enable_per_register_keymap = true,
})
```

| Property | Description | Type | Default |
|-|-|-|-|
| default_launch_mode | macroedit window layout on open | 'current', 'minimal', 'split', 'vsplit' | current |
| default_macro_register | if a register is not specified, this register is used by default | string | 'q' |
| default_mappings | macroedit buffer mappings for quick actions | table | **WIP** |
| enable_per_register_keymap | enable *c@<reg>* mappings to quickly edit specific registers | boolean | true |

## Future Features
Features will be added whenever I feel like working on them.
This list will be updated/added to/removed from, as things get implemented or I change my mind on them.
- [ ] nvim help documentation
- [ ] flesh out readme
- [ ] UI additions / updates (names may change)
	- [x] minimal: a single macro editing window
	- [x] split: 3-way split window
	- [x] vsplit: 3-way vsplit window
	- [x] current: macroediting window float, run against active buffer/window instead of scratch buffer
	- [ ] page: open a new tab
	- [ ] consider floating windows for the split options
	- [ ] ability to toggle between window layouts
	- [x] configure a option for default startup
	- [ ] Window titles/indicators
	- [ ] Better highlighting setup of scratch windows
	- [ ] Custom highlighting of macro editing buffer?
- [ ] Additional arguments
	- [ ] take in mark range
	- [ ] take in current visual selection
	- [ ] take in positional arguments?
- [ ] improve macro editing experience (use CTRL-V automatically?)
- [ ] Live changes while editing in insert mode
- [ ] Additional mappings
	- [ ] for navigation between created windows/buffers
	- [ ] closing/opening controlled windows/buffers
	- [ ] saving macro to a register
- [ ] saved macros?
	- [ ] macros created on startup
	- [ ] a way to select these macros
- [ ] other useful macro QoL helpers
