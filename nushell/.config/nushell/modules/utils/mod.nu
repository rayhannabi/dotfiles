export use mime.nu *
export use preview.nu *
export alias p = preview

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

export def uname [] {
    %uname | {
        kernel: $in.kernel-name?
        release: $in.kernel-release
        version: $in.kernel-version
        arch: $in.machine
        os: $in.operating-system
        nodename: $in.nodename
    }
}
