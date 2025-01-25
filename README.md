# dotnet-nvim

A Neovim plugin to simplify working with the .NET CLI directly from your editor.

## Features
- Run any `dotnet` command, such as `build`, `run`, `test`, etc.
- Auto-completion for common .NET CLI commands and directories.
- Executes commands in the context of the directory of the currently opened buffer.

## Installation

### Using lazy.nvim
Add the following to your lazy.nvim configuration:

```lua
require("lazy").setup {
  {
    "kat-lego/dotnet-nvim",
    config = function()
      require("dotnet-nvim").setup()
    end,
  },
}
```

## Usage

### Commands
- `:Dotnet [args...]` - Runs a `dotnet` command with the provided arguments.

Examples:
- `:Dotnet build` - Builds the project in the current buffer's directory.
- `:Dotnet run` - Runs the application.
- `:Dotnet test` - Executes unit tests.

### Auto-completion
The `:Dotnet` command provides auto-completion for common .NET commands and directory paths.

## License
This plugin is open-source and available under the MIT License.
