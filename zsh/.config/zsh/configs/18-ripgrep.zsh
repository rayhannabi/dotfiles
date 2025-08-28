#!/bin/zsh
#
# Ripgrep
#

RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
RG_HIDDEN_PREFIX="$RG_PREFIX--hidden "
RG_IGNORE_PREFIX="$RG_PREFIX--no-ignore "
RG_ALL_PREFIX="$RG_PREFIX--hidden -no-ignore "

rf() {
  rm -f /tmp/rg-fzf-{r,f}

  INITIAL_QUERY="${*:-}"

  fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --bind "start:reload:$RG_PREFIX {q}" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --bind 'alt-t:transform:[[ ! $FZF_PROMPT =~ ripgrep ]] &&
      echo "rebind(change)+change-prompt(ripgrep > )+disable-search+transform-query:echo \{q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r" ||
      echo "unbind(change)+change-prompt(fzf > )+enable-search+transform-query:echo \{q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f"' \
    --prompt 'ripgrep > ' \
    --delimiter : \
    --preview 'bat --color=always {1} --highlight-line {2}' \
    --bind 'enter:become(nvim {1} +{2})'
}
