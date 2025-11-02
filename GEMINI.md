# Dotfiles Project Overview

This repository contains personal configuration files (dotfiles) for a variety of command-line tools and applications. The configurations are managed using `stow`, a symlink farm manager, which simplifies the process of deploying these dotfiles to the correct locations in the user's home directory.

The overall aesthetic is based on the "Tokyonight" theme, which is used across multiple applications for a consistent look and feel. The configurations are tailored for a development environment, with a focus on shell and editor enhancements.

## Key Technologies and Tools

*   **Terminal:** Ghostty and Kitty
*   **Shell:** Zsh, configured with `zsh-autosuggestions` and `zsh-syntax-highlighting`.
*   **Prompt:** Starship, a highly customizable cross-shell prompt.
*   **Editor:** Neovim, using the LazyVim distribution for a modern and feature-rich setup.
*   **Git UI:** Lazygit, a terminal-based UI for Git.
*   **Fonts:** JetBrains Mono, Input Mono, and Nerd Fonts are used to provide a consistent and icon-rich experience in the terminal.

## Building and Running

There is no "build" process for this project. The configurations are "installed" by creating symbolic links from this repository to the user's home directory.

The primary tool for this is `stow`. To install a configuration, use the `stow` command followed by the name of the directory for the tool you want to configure.

**Example:**

To install the Neovim configuration, run the following command from the root of this repository:

```sh
stow nvim
```

This will create a symbolic link from `nvim/.config/nvim` in this repository to `~/.config/nvim`.

## Development Conventions

*   **Structure:** Each tool's configuration is contained within its own directory at the root of the repository. This makes it easy to manage and `stow` each configuration independently.
*   **Theming:** The "Tokyonight" theme is used consistently across different tools to provide a unified visual experience.
*   **Modularity:** The Zsh configuration is broken down into smaller, modular files for functions, configurations, and plugins, which are then sourced from the main `.zshrc` file. This makes it easier to manage and debug the shell setup.
