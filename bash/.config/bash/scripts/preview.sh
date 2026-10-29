#!/usr/bin/env bash
#
# Preview a file: syntax-highlighted text, inline image (kitty graphics
# protocol), or a file-info summary as a fallback.
#
# Used directly (via the `preview`/`p` function+alias) and as fzf's
# --preview command, so it must run standalone without sourcing the rest
# of the shell config.

_is_fzf_preview() {
    [[ -n "$FZF_PREVIEW_COLUMNS" && -n "$FZF_PREVIEW_LINES" && -n "$FZF_PREVIEW_TOP" && -n "$FZF_PREVIEW_LEFT" ]]
}

_preview_text() {
    local file="$1"
    if command -v bat >/dev/null 2>&1; then
        bat -p --pager=never --color=always "$file"
    elif command -v batcat >/dev/null 2>&1; then
        batcat -p --pager=never --color=always "$file"
    else
        cat "$file"
    fi
}

_preview_image() {
    local file="$1"
    if _is_fzf_preview; then
        local place="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0"
        kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="$place" "$file"
    else
        kitten icat --align=left --fit=width "$file"
    fi
}

_preview_fallback() {
    local file="$1"
    local size desc type

    size="$(du -h --apparent-size -- "$file" 2>/dev/null | cut -f1)"
    [[ -z "$size" ]] && size="$(du -h -- "$file" 2>/dev/null | cut -f1)"
    desc="$(file -- "$file" 2>/dev/null | sed 's/^[^:]*: //')"
    type="$(file --brief --mime-type -- "$file" 2>/dev/null)"

    printf "file: %s\n" "$file"
    printf "desc: %s\n" "$desc"
    printf "type: %s\n" "$type"
    printf "size: %s\n" "$size"
}

main() {
    local file="$1"

    if [[ -z "$file" ]]; then
        echo "Usage: preview <path>" >&2
        exit 1
    fi

    if [[ ! -e "$file" ]]; then
        echo "preview: no such file: $file" >&2
        exit 1
    fi

    local mime type subtype
    mime="$(file --brief --dereference --mime -- "$file" 2>/dev/null)"
    type="${mime%%/*}"
    subtype="${mime#*/}"
    subtype="${subtype%%;*}"

    if [[ "$type" == "text" || "$subtype" == "json" || "$subtype" == "xml" ]]; then
        _preview_text "$file"
    elif [[ "$type" == "image" ]]; then
        _preview_image "$file"
    elif [[ "$mime" == *"charset="*"ascii"* ]]; then
        _preview_text "$file"
    else
        _preview_fallback "$file"
    fi
}

main "$@"
