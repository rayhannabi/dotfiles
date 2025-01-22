# Configuring ZSH

ZSH requires a `.zshenv` file to be present in the
user's home directory. Location for the rest of the configurations
can be anywhere by setting the `ZDOTDIR` variable.

**STEP 1:** Create the env file

```sh
touch $HOME/.zshenv
```

**STEP 2:** Set `XDG_` directories and the `ZDOTDIR` -

```sh
## $HOME/.zshenv

# XDG Paths
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# ZSH
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
```

**STEP 3:** Run `stow` while inside the dotfiles directory -

```sh
stow zsh; exec zsh
```

## How it works

| Directory | Location               |
| --------- | ---------------------- |
| *functions* | `$ZDOTDIR/zsh/functions` |
| *configs*   | `$ZDOTDIR/zsh/configs`   |
| *plugins* | `$ZDOTDIR/zsh/plugins`   |

In the `.zshrc` file the files from the *functions* and
*configs* directories are loaded in order and sourced.
These are all `.zsh` files, any POSIX-complaint shell
should be able to use these.

To add a new config, create a file inside the *configs* directory.

> 💡 **NOTE**
>
> Plugins are git submodules and manually sourced in the `.zshrc` file.
> To update these, run -
>
> ```sh
> git submodule update --recursive
> ```
