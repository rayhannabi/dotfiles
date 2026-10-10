export def ll [path?: path] {
    %ls -al ($path | default ".")
    | sort-by type name
    | select name size modified user mode
    | table -o
}

export def lll [path?: path] {
    %ls -al ($path | default ".")
    | sort-by type name
    | table -o
}
