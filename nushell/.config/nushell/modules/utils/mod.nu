export def ll [path?: path] {
    %ls -al ($path | default ".")
    | select name size modified user mode
    | table -o
}

export def lll [path?: path] {
    %ls -al ($path | default ".")
    | table -o
}
