export def main [file?: path, --text(-t)] {
    let file = $file | default $in
    let type = ^file --brief --dereference --mime $file
    | lines
    | first

    if $text {
        $type | str trim
    } else {
        $type
        | parse --regex '^(?<type>[^/]+)/(?<subtype>[^;]+?)(?:;\s*(?<key>[^=;]+?)=(?<value>[^;]+))?$'
        | first
    }
}
