# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles managed with GNU `stow`. Each top-level directory is a stow package mirroring the target layout under `$HOME` (e.g. `nvim/.config/nvim/...` → `~/.config/nvim/...`). There is no build, lint, or test suite — this is configuration, not code.

## Common commands

```sh
# Deploy a package's symlinks into $HOME (run from repo root)
stow nvim
stow zsh fish starship   # multiple packages at once

# Remove a package's symlinks
stow -D nvim

# Zsh plugins are git submodules, not stow packages
git submodule init
git submodule update --recursive
```

Zsh requires `$ZDOTDIR` to be set (in `~/.zshenv`) to `$XDG_CONFIG_HOME/zsh` *before* `stow zsh` is run — see `zsh/.config/zsh/README.md` for the exact setup steps.

## Architecture

- **Stow packages**: each top-level dir (`nvim/`, `zsh/`, `fish/`, `starship/`, `ghostty/`, `kitty/`, `lazygit/`, `bash/`, `nushell/`) is independent and stow-able on its own; adding a new tool means adding a new top-level dir with the same `.config/<tool>` nesting.
- **Zsh**: `.zshrc` sources `configs/*.zsh` and `functions/*.zsh` in lexical order, which is why those files are numerically prefixed (`00-`, `01-`, ...) — insertion order matters. Plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`) live under `plugins/` as git submodules, manually sourced in `.zshrc`, not managed by a plugin manager.
- **Fish**: mirrors the same idea via fish's native `conf.d/*.fish` (auto-sourced, numerically prefixed for order) and `functions/*.fish` (lazy-loaded by filename).
- **Neovim**: LazyVim-based. `init.lua` → `lua/config/lazy.lua` bootstraps `lazy.nvim` and loads `{ import = "lazyvim.plugins" }` plus the local `{ import = "plugins" }` spec. Each file under `lua/plugins/` returns a lazy.nvim plugin spec table and either adds a new plugin or overrides/extends a LazyVim default (e.g. `colorscheme.lua` sets Tokyonight, `lspconfig.lua`/`conform.lua` extend LazyVim's LSP/formatting defaults). `lua/config/{options,keymaps,autocmds}.lua` hold non-plugin Neovim settings. `lazy-lock.json` pins plugin versions — update it via Neovim's `:Lazy` UI, not by hand.
- **Theming**: Tokyonight (Night variant) is the consistent theme across terminals/editor/prompt; when adding a new tool's config, match this theme rather than introducing a new one.
