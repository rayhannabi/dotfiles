use mime.nu

export def main [item: path] {
    try {
        let $mime = mime $item

        match $mime {
            {type: "text"} | {subtype: "json"} | {subtype: "xml"} => (preview text $item)
            {type: "image"} => (preview image $item)
            # {subtype: "pdf"} => (preview pdf $item)
            {key: "charset", value: $v} if $v =~ "ascii" => (preview text $item)
            _ => (preview-fallback $item)
        }
    } catch {
        preview-fallback $item
    }
}

export def "preview text" [file: path] {
    try {
        ^bat -p --pager=never --color=always $file
    } catch {
        try {
            ^batcat -p --pager=never --color=always $file
        } catch {
            cat $file
        }
    }
}

export def "preview image" [file: path] {
    if (is-fzf-preview) {
        let size = fzf-preview-size
        let dim = $"($size.column)x($size.row)"
        let place = $"($dim)@0x0"
        ^kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place=($place) $file
    } else {
        ^kitten icat --align=left --fit=width $file
    }
}

export def "preview pdf" [file: path] {
    if (is-fzf-preview) {
        let size = fzf-preview-size
        let dim = $"($size.column)x($size.row)"
        let place = $"($dim)@0x0"
        (
            ^kitten icat 
                --background=white 
                --clear 
                --transfer-mode=memory 
                --unicode-placeholder 
                --stdin=no 
                --place=($place) 
                $file
        )
    } else {
        ^kitten icat --align=left --fit=width --background=white $file
    }
}

def preview-fallback [file] {
    try {
        let is_f = is-fzf-preview
        let size = du $file | first | get apparent
        let type = mime -t $file

        let desc = ^file $file
        | parse "{_}:{d}"
        | get d.0
        | str trim

        let p = {
            file: $file
            desc: $desc
            type: $type
            size: $size
        }

        if (is-fzf-preview) {
            $p | table --width (fzf-preview-size | get column | into int)
        } else {
            $p
        }
    } catch {
        echo $file
    }
}

def is-fzf-preview [] {
    let size = fzf-preview-size
    [$size.column, $size.row, $size.top, $size.left] | all { is-not-empty }
}

def fzf-preview-size [] {
    {
        column: $env.FZF_PREVIEW_COLUMNS?
        row: $env.FZF_PREVIEW_LINES?
        top: $env.FZF_PREVIEW_TOP?
        left: $env.FZF_PREVIEW_LEFT?
    }
}
