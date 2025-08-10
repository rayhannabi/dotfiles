#!/bin/zsh
#
# Completion
#

fpath=($ZDOTDIR/plugins/zsh-completions/src $fpath)

zmodload zsh/complist 

autoload -Uz compinit; compinit
autoload -Uz bashcompinit; bashcompinit
_cmp_options+=(globdots)

setopt MENU_COMPLETE
setopt AUTO_LIST
setopt COMPLETE_IN_WORD

## zstyles
## pattern: :completion:<function>:<completer>:<command>:<argument>:<tag>

# completers
zstyle ':completion:*' completer _extensions _complete _approximate

# Use cache for completion
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

# complete alias
zstyle ':completion:*' complete true
zstyle ':completion:alias-expansion:*' completer _expand_alias

# default options
zstyle ':completion:*' menu select
zstyle ':completion:*' complete-options true
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}  %d (errors: %e)%f'
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}  %d%f'
zstyle ':completion:*:*:*:*:messages' format ' %F{purple}  %d%f'
zstyle ':completion:*:*:*:*:warnings' format ' %F{red}  no matches found%f'

# Colors for files and directory
zstyle ':completion:*:*:*:*:default' list-colors ${(s.:.)LS_COLORS}

# Only display some tags for the command cd
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories

# Required for completion to be in good groups (named after the tags)
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands

# See ZSHCOMPWID "completion matching control"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' keep-prefix true

zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'


