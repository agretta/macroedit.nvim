# macroedit.nvim

A neovim plugin for editing and visualizing macros.
Edit macros in a floating window from a register, and test them on scratch buffers to make sure that the macro is doing what you want.

My first foray into lua and making plugins for neovim, this is a learning experience for me and I make no promises of future features/maintenance.

## Features
**[WIP]**

**Commands**
|Command|Description|Notes|
|-|-|-|
|MacroEditOpen register selection | Open the MacroEdit windows | - |
|MacroEditClose | Close the MacroEdit windows| - |
|MacroEditToggle register selection | Toggle open/closed the MacroEditWindows| - |

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
**[WIP]**

## Configuration
**macroedit.nvim** comes with the following defaults **[WIP]**

```
{}
```

## Limitations
**[WIP]**

## Future Features
Features will be added whenever I feel like working on them.
This list will be updated/added to/removed from, as things get implemented or I change my mind on them.
- [ ] nvim help documentation
- [ ] flesh out readme
- [ ] UI additions / updates (names may change)
	- [ ] minimal: a single macro editing window
	- [ ] split: 3-way split window (floating)
	- [ ] vsplit: 3-way vsplit window (floating/not floating?)
	- [ ] bottom-up: macroediting window on bottom, reverse order
	- [ ] sideways: macroediting window on the side of the 2 visual windows
	- [ ] in-buffer: macroediting window float, run against active buffer/window instead of scratch buffer
	- [ ] ability to toggle between these
	- [ ] configure a option for default startup
	- [ ] Window titles/indicators
	- [ ] Better highlighting setup of scratch windows
- [ ] Additional arguments
	- [ ] take in mark range
	- [ ] take in current visual selection
	- [ ] take in positional arguments?
- [ ] Live changes while editing in insert mode
- [ ] Additional mappings 
	- [ ] for navigation between created windows/buffers
	- [ ] closing/opening controlled windows/buffers
	- [ ] saving macro to a register
- [ ] saved macros?
	- [ ] macros created on startup
	- [ ] a way to select these macros
- [ ] other useful macro QoL helpers
