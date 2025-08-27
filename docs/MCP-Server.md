---
last_review_date: "2025-07-18"
---

# Homebrew's MCP Server

Homebrew's MCP Server is the official MCP ([Model Context Protocol](https://modelcontextprotocol.io/)) server for Homebrew.

You don't need to do anything to install it.
It's provided by default with Homebrew through the `brew mcp-server` command.

## Usage

Run `brew mcp-server` to launch the Homebrew MCP Server.

```bash
$ brew mcp-server
==> Started Homebrew MCP server...
```

Press Ctrl-D or Ctrl-C to terminate it.

## Configuration

### Example configuration for [Cursor](https://www.cursor.com/)

```json
{
  "mcpServers": {
    "Homebrew": {
      "command": "brew mcp-server"
    }
  }
}
```

### Example configuration for [VSCode](https://code.visualstudio.com/)

```json
{
  "mcp": {
    "servers": {
      "Homebrew": {
        "type": "stdio",
        "command": "brew",
        "args": ["mcp-server"]
      }
    }
  }
}
```

### Example configuration for [Zed](https://github.com/zed-industries/zed)

```json
{
  "context_servers": {
    "Homebrew": {
      "command": {
        "path": "brew",
        "args": ["mcp-server"]
      }
    }
  }
}
```

### Example configuration for [Claude Desktop](https://claude.ai/download)

```json
{
  "mcpServers": {
    "Homebrew": {
      "command": "brew mcp-server"
    }
  }
}
```

## Available Tools

The Homebrew MCP Server provides the following tools:

| Tool | Description |
|------|-------------|
| `search` | Perform a substring search of cask tokens and formula names. If text is flanked by slashes, it is interpreted as a regular expression. |
| `info` | Display brief statistics for your Homebrew installation. If a formula or cask is provided, show summary of information about it. |
| `install` | Install a formula or cask. |
| `update` | Fetch the newest version of Homebrew and all formulae from GitHub using git and perform any necessary migrations. |
| `upgrade` | Upgrade outdated casks and outdated, unpinned formulae using the same options they were originally installed with. If cask or formula are specified, upgrade only the given cask or formula kegs (unless they are pinned). |
| `uninstall` | Uninstall a formula or cask. |
| `list` | List all installed formulae and casks. If formula is provided, summarise the paths within its current keg. If cask is provided, list its artifacts. |
| `config` | Show Homebrew and system configuration info useful for debugging. If you file a bug report, you will be required to provide this information. |
| `doctor` | Check your system for potential problems. Will exit with a non-zero status if any potential problems are found. |
| `typecheck` | Check for typechecking errors using Sorbet. |
| `style` | Check formulae or files for conformance to Homebrew style guidelines. |
| `tests` | Run Homebrew's unit and integration tests. |
| `commands` | Show lists of built-in and external commands. |
| `help` | Outputs the usage instructions for a brew command. |
