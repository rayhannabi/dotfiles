# fzf.nu

use ../modules/term.nu

let opts = if (term is-nice) {
    {prompt:"󰍉 ", pointer: " ", marker: "✓ "}
} else {
    {prompt:"? ", pointer: "> ", marker: "+ "}
}

let preview = match ($nu.os-info | get name) {
    macos => "fzf-preview.sh"
    linux => "/usr/share/fzf/fzf-preview.sh"
    _ => "fzf-preview.sh"
}

let fzf_colors = {
    bg: -1
    bg+: -1
    fg: white
    fg+: yellow
    border: gray
    spinner: magenta
    hl: yellow
    header: blue
    info: green
    pointer: yellow
    marker: green
    prompt: blue
    hl+: red
}
| items { |key, value| $"($key):($value)" }
| str join ","

let fzf_interface_opts = {
    style: full
    layout: reverse
    prompt: $"'($opts.prompt)'"
    pointer: $"'($opts.pointer)'"
    marker: $"'($opts.marker)'"
    gutter: "' '"
    color: $"'($fzf_colors)'"
    preview: $"'($preview) {}'"
}
| items { |key, value| $"--($key) ($value)"}

let fzf_keybindings = {
    ctrl-e: "become(nvim {+})"
    ctrl-o: "become(bat {+})"
    ctrl-y: "execute(echo {} | pbcopy && echo Copied path to clipboard: {})+become(exit 0)"
    ctrl-u: "execute(cat {} | pbcopy && echo Copied contents to clipboard: {})+become(exit 0)"
    ctrl-/: "change-preview-window(hidden|)"
    esc: "become(exit 0)"
}
| items { |key, value| $"--bind '($key):($value)'" }

$env.FZF_DEFAULT_OPTS = [...$fzf_interface_opts, ...$fzf_keybindings] | str join " "
$env.FZF_ALT_C_OPTS = "--preview 'eza -T {}' --bind 'ctrl-/:change-preview-window(hidden|)'"

# Check whether we have fzf completion installed in vendor autoload.
# if not run setup fzf

use ../modules/setup/fzf.nu *

if not ($env.FZF_INTEGRATION_PATH | path exists) {
    setup fzf
}
