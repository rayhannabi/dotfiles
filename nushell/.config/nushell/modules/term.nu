# term.nu

export def is-nice [] {
     let term_programs = [
        "ghostty"
        "kitty"
        "iTerm.app"
        "vscode"
        "Apple_Terminal"
    ]

    let term_names = [
        "xterm-ghostty"
        "xterm-kitty"
        "alacritty"
        "terminator"
        "konsole"
        "hyper"
        "foot"
        "wezterm"
        "rio"
        "xterm-256color"
        "tmux-256color"
        "screen-256color"
    ]

    (
        $term_programs 
        | any {|it| $it == ($env.TERM_PROGRAM? | default "") }
    ) or (
        $term_names 
        | any {|it| $it == ($env.TERM? | default "") }
    )
}
