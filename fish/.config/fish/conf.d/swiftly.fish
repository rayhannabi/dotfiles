#!/usr/bin/env fish

## For now support only linux swiftly toolchain
if test (uname) = Linux
    set -x SWIFTLY_HOME_DIR $HOME/.local/share/swiftly
    set -x SWIFTLY_BIN_DIR $SWIFTLY_HOME_DIR/bin
    set -x SWIFTLY_TOOLCHAINS_DIR $SWIFTLY_HOME_DIR/toolchains

    # preprend swiftly bin to PATH if not already present
    if not contains $SWIFTLY_BIN_DIR $PATH
        set -gx PATH $SWIFTLY_BIN_DIR $PATH
    end
end
