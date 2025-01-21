export ZSH_CONFIGS="$ZDOTDIR/configs"
export ZSH_FUNCTIONS="$ZDOTDIR/functions"
export ZSH_PLUGINS="$ZDOTDIR/plugins"

# Load zsh functions
for file in $ZSH_FUNCTIONS/*; do
  [[ -f "$file" ]] && source "$file"
done

# Load zsh configs, globals, aliases
for file in $ZSH_CONFIGS/*; do
  [[ -f "$file" ]] && source "$file"
done

