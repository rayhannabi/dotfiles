#!/bin/bash

__swift_cursor_index_in_current_word() {
    local remaining="${COMP_LINE}"

    local word
    for word in "${COMP_WORDS[@]::COMP_CWORD}"; do
        remaining="${remaining##*([[:space:]])"${word}"*([[:space:]])}"
    done

    local -ir index="$((COMP_POINT - ${#COMP_LINE} + ${#remaining}))"
    if [[ "${index}" -le 0 ]]; then
        printf 0
    else
        printf %s "${index}"
    fi
}

# positional arguments:
#
# - 1: the current (sub)command's count of positional arguments
#
# required variables:
#
# - flags: the flags that the current (sub)command can accept
# - options: the options that the current (sub)command can accept
# - positional_number: value ignored
# - unparsed_words: unparsed words from the current command line
#
# modified variables:
#
# - flags: remove flags for this (sub)command that are already on the command line
# - options: remove options for this (sub)command that are already on the command line
# - positional_number: set to the current positional number
# - unparsed_words: remove all flags, options, and option values for this (sub)command
__swift_offer_flags_options() {
    local -ir positional_count="${1}"
    positional_number=0

    local was_flag_option_terminator_seen=false
    local is_parsing_option_value=false

    local -ar unparsed_word_indices=("${!unparsed_words[@]}")
    local -i word_index
    for word_index in "${unparsed_word_indices[@]}"; do
        if "${is_parsing_option_value}"; then
            # This word is an option value:
            # Reset marker for next word iff not currently the last word
            [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]] && is_parsing_option_value=false
            unset "unparsed_words[${word_index}]"
            # Do not process this word as a flag or an option
            continue
        fi

        local word="${unparsed_words["${word_index}"]}"
        if ! "${was_flag_option_terminator_seen}"; then
            case "${word}" in
            --)
                unset "unparsed_words[${word_index}]"
                # by itself -- is a flag/option terminator, but if it is the last word, it is the start of a completion
                if [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]]; then
                    was_flag_option_terminator_seen=true
                fi
                continue
                ;;
            -*)
                # ${word} is a flag or an option
                # If ${word} is an option, mark that the next word to be parsed is an option value
                local option
                for option in "${options[@]}"; do
                    [[ "${word}" = "${option}" ]] && is_parsing_option_value=true && break
                done

                # Remove ${word} from ${flags} or ${options} so it isn't offered again
                local not_found=true
                local -i index
                for index in "${!flags[@]}"; do
                    if [[ "${flags[${index}]}" = "${word}" ]]; then
                        unset "flags[${index}]"
                        flags=("${flags[@]}")
                        not_found=false
                        break
                    fi
                done
                if "${not_found}"; then
                    for index in "${!options[@]}"; do
                        if [[ "${options[${index}]}" = "${word}" ]]; then
                            unset "options[${index}]"
                            options=("${options[@]}")
                            break
                        fi
                    done
                fi
                unset "unparsed_words[${word_index}]"
                continue
                ;;
            esac
        fi

        # ${word} is neither a flag, nor an option, nor an option value
        if [[ "${positional_number}" -lt "${positional_count}" ]]; then
            # ${word} is a positional
            ((positional_number++))
            unset "unparsed_words[${word_index}]"
        else
            if [[ -z "${word}" ]]; then
                # Could be completing a flag, option, or subcommand
                positional_number=-1
            else
                # ${word} is a subcommand or invalid, so stop processing this (sub)command
                positional_number=-2
            fi
            break
        fi
    done

    unparsed_words=("${unparsed_words[@]}")

    if\
        ! "${was_flag_option_terminator_seen}"\
        && ! "${is_parsing_option_value}"\
        && [[ ("${cur}" = -* && "${positional_number}" -ge 0) || "${positional_number}" -eq -1 ]]
    then
        COMPREPLY+=($(compgen -W "${flags[*]} ${options[*]}" -- "${cur}"))
    fi
}

__swift_add_completions() {
    local completion
    while IFS='' read -r completion; do
        COMPREPLY+=("${completion}")
    done < <(IFS=$'\n' compgen "${@}" -- "${cur}")
}

__swift_custom_complete() {
    if [[ -n "${cur}" || -z ${COMP_WORDS[${COMP_CWORD}]} || "${COMP_LINE:${COMP_POINT}:1}" != ' ' ]]; then
        local -ar words=("${COMP_WORDS[@]}")
    else
        local -ar words=("${COMP_WORDS[@]::${COMP_CWORD}}" '' "${COMP_WORDS[@]:${COMP_CWORD}}")
    fi

    "${COMP_WORDS[0]}" "${@}" "${words[@]}"
}

_swift() {
    trap "$(shopt -p);$(shopt -po)" RETURN
    shopt -s extglob
    set +o history +o posix

    local -xr SAP_SHELL=bash
    local -x SAP_SHELL_VERSION
    SAP_SHELL_VERSION="$(IFS='.';printf %s "${BASH_VERSINFO[*]}")"
    local -r SAP_SHELL_VERSION

    local -r cur="${2}"
    local -r prev="${3}"

    local -i positional_number
    local -a unparsed_words=("${COMP_WORDS[@]:1:${COMP_CWORD}}")

    local -a flags=(-h --help)
    local -a options=()
    __swift_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    run|build|test|package|help)
        # Offer subcommand argument completions
        "_swift_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'run build test package help' -- "${cur}"))
        ;;
    esac
}

_swift_run() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --repl --debugger --run --skip-build --build-tests --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 2

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac

    # Offer positional completions
    case "${positional_number}" in
    1)
        __swift_add_completions -W "$(eval 'swift package completion-tool list-executables')"
        return
        ;;
    esac
}

_swift_build() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --build-tests --enable-code-coverage --disable-code-coverage --show-bin-path --print-manifest-job-graph --print-pif-manifest-graph --enable-xctest --disable-xctest --enable-swift-testing --disable-swift-testing --static-swift-stdlib --no-static-swift-stdlib --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --target --product)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--target')
        return
        ;;
    '--product')
        return
        ;;
    esac
}

_swift_test() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --skip-build --enable-xctest --disable-xctest --enable-swift-testing --disable-swift-testing --parallel --no-parallel --list-tests -l --show-codecov-path --show-code-coverage-path --show-coverage-path --enable-testable-imports --disable-testable-imports --enable-code-coverage --disable-code-coverage --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --attachments-path --num-workers -s --specifier --filter --skip --xunit-output)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--attachments-path')
        __swift_add_completions -d
        return
        ;;
    '--num-workers')
        return
        ;;
    '-s'|'--specifier')
        return
        ;;
    '--filter')
        return
        ;;
    '--skip')
        return
        ;;
    '--xunit-output')
        __swift_add_completions -d
        return
        ;;
    esac

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    list|last)
        # Offer subcommand argument completions
        "_swift_test_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'list last' -- "${cur}"))
        ;;
    esac
}

_swift_test_list() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --skip-build --enable-xctest --disable-xctest --enable-swift-testing --disable-swift-testing --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --attachments-path)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--attachments-path')
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_test_last() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    add-dependency|add-product|add-target|add-target-dependency|add-setting|experimental-audit-binary-artifact|clean|purge-cache|reset|update|describe|init|migrate|experimental-install|experimental-uninstall|diagnose-api-breaking-changes|dump-symbol-graph|dump-package|edit|unedit|config|resolve|show-dependencies|show-executables|show-traits|tools-version|compute-checksum|archive-source|completion-tool|plugin)
        # Offer subcommand argument completions
        "_swift_package_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'add-dependency add-product add-target add-target-dependency add-setting experimental-audit-binary-artifact clean purge-cache reset update describe init migrate experimental-install experimental-uninstall diagnose-api-breaking-changes dump-symbol-graph dump-package edit unedit config resolve show-dependencies show-executables show-traits tools-version compute-checksum archive-source completion-tool plugin' -- "${cur}"))
        ;;
    esac
}

_swift_package_add-dependency() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --exact --revision --branch --from --up-to-next-minor-from --to --type)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--exact')
        return
        ;;
    '--revision')
        return
        ;;
    '--branch')
        return
        ;;
    '--from')
        return
        ;;
    '--up-to-next-minor-from')
        return
        ;;
    '--to')
        return
        ;;
    '--type')
        __swift_add_completions -W 'url'$'\n''path'$'\n''registry'
        return
        ;;
    esac
}

_swift_package_add-product() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --type --targets)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--type')
        __swift_add_completions -W 'executable'$'\n''library'$'\n''static-library'$'\n''dynamic-library'$'\n''plugin'
        return
        ;;
    '--targets')
        return
        ;;
    esac
}

_swift_package_add-target() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --type --dependencies --url --path --checksum --testing-library)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--type')
        __swift_add_completions -W 'library'$'\n''executable'$'\n''test'$'\n''macro'
        return
        ;;
    '--dependencies')
        return
        ;;
    '--url')
        return
        ;;
    '--path')
        return
        ;;
    '--checksum')
        return
        ;;
    '--testing-library')
        return
        ;;
    esac
}

_swift_package_add-target-dependency() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --package)
    __swift_offer_flags_options 2

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--package')
        return
        ;;
    esac
}

_swift_package_add-setting() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --target --swift)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--target')
        return
        ;;
    '--swift')
        return
        ;;
    esac
}

_swift_package_experimental-audit-binary-artifact() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac

    # Offer positional completions
    case "${positional_number}" in
    1)
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_package_clean() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_purge-cache() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_reset() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_update() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --dry-run -n --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_describe() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --type)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--type')
        __swift_add_completions -W 'json'$'\n''text'$'\n''mermaid'
        return
        ;;
    esac
}

_swift_package_init() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --enable-xctest --disable-xctest --enable-swift-testing --disable-swift-testing --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --type --name)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--type')
        return
        ;;
    '--name')
        return
        ;;
    esac
}

_swift_package_migrate() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --target --to-feature)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--target')
        return
        ;;
    '--to-feature')
        return
        ;;
    esac
}

_swift_package_experimental-install() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --product)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--product')
        return
        ;;
    esac
}

_swift_package_experimental-uninstall() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_diagnose-api-breaking-changes() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --regenerate-baseline --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --breakage-allowlist-path --products --targets --baseline-dir)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--breakage-allowlist-path')
        __swift_add_completions -d
        return
        ;;
    '--products')
        return
        ;;
    '--targets')
        return
        ;;
    '--baseline-dir')
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_package_dump-symbol-graph() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --pretty-print --skip-synthesized-members --skip-inherited-docs --include-spi-symbols --emit-extension-block-symbols --omit-extension-block-symbols --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --minimum-access-level)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--minimum-access-level')
        __swift_add_completions -W 'private'$'\n''fileprivate'$'\n''internal'$'\n''package'$'\n''public'$'\n''open'
        return
        ;;
    esac
}

_swift_package_dump-package() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_edit() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --revision --branch --path)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--revision')
        return
        ;;
    '--branch')
        return
        ;;
    '--path')
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_package_unedit() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --force --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac
}

_swift_package_config() {
    flags=(--version -help -h --help)
    options=()
    __swift_offer_flags_options 0

    # Offer subcommand / subcommand argument completions
    local -r subcommand="${unparsed_words[0]}"
    unset 'unparsed_words[0]'
    unparsed_words=("${unparsed_words[@]}")
    case "${subcommand}" in
    set-mirror|unset-mirror|get-mirror)
        # Offer subcommand argument completions
        "_swift_package_config_${subcommand}"
        ;;
    *)
        # Offer subcommand completions
        COMPREPLY+=($(compgen -W 'set-mirror unset-mirror get-mirror' -- "${cur}"))
        ;;
    esac
}

_swift_package_config_set-mirror() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --original --mirror)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--original')
        return
        ;;
    '--mirror')
        return
        ;;
    esac
}

_swift_package_config_unset-mirror() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --original --mirror)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--original')
        return
        ;;
    '--mirror')
        return
        ;;
    esac
}

_swift_package_config_get-mirror() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --original)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--original')
        return
        ;;
    esac
}

_swift_package_resolve() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --version --branch --revision)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--version')
        return
        ;;
    '--branch')
        return
        ;;
    '--revision')
        return
        ;;
    esac
}

_swift_package_show-dependencies() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --format --output-path -o)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--format')
        __swift_add_completions -W 'text'$'\n''dot'$'\n''json'$'\n''flatlist'
        return
        ;;
    '--output-path'|'-o')
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_package_show-executables() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --format)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--format')
        __swift_add_completions -W 'flatlist'$'\n''json'
        return
        ;;
    esac
}

_swift_package_show-traits() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --package-id --format)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--package-id')
        return
        ;;
    '--format')
        __swift_add_completions -W 'text'$'\n''json'
        return
        ;;
    esac
}

_swift_package_tools-version() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --set-current --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --set)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--set')
        return
        ;;
    esac
}

_swift_package_compute-checksum() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac

    # Offer positional completions
    case "${positional_number}" in
    1)
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_package_archive-source() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits -o --output)
    __swift_offer_flags_options 0

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '-o'|'--output')
        __swift_add_completions -d
        return
        ;;
    esac
}

_swift_package_completion-tool() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits)
    __swift_offer_flags_options 1

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    esac

    # Offer positional completions
    case "${positional_number}" in
    1)
        __swift_add_completions -W 'generate-bash-script'$'\n''generate-zsh-script'$'\n''generate-fish-script'$'\n''list-dependencies'$'\n''list-executables'$'\n''list-snippets'
        return
        ;;
    esac
}

_swift_package_plugin() {
    flags=(--enable-dependency-cache --disable-dependency-cache --enable-build-manifest-caching --disable-build-manifest-caching --enable-experimental-prebuilts --disable-experimental-prebuilts --verbose -v --very-verbose --vv --quiet -q --color-diagnostics --no-color-diagnostics --disable-sandbox --netrc --enable-netrc --disable-netrc --enable-signature-validation --disable-signature-validation --enable-prefetching --disable-prefetching --force-resolved-versions --disable-automatic-resolution --only-use-versions-from-resolved-file --skip-update --disable-scm-to-registry-transformation --use-registry-identity-for-scm --replace-scm-with-registry --auto-index-store --enable-index-store --disable-index-store --enable-parseable-module-interfaces --use-integrated-swift-driver --enable-dead-strip --disable-dead-strip --disable-local-rpath --enable-all-traits --disable-default-traits --list --allow-writing-to-package-directory --version -help -h --help)
    options=(--package-path --cache-path --config-path --security-path --scratch-path --swift-sdks-path --toolset --pkg-config-path --manifest-cache --netrc-file --resolver-fingerprint-checking --resolver-signing-entity-checking --default-registry-url --configuration -c -Xcc -Xswiftc -Xlinker -Xcxx --triple --sdk --toolchain --swift-sdk --sanitize --jobs -j --explicit-target-dependency-import-check --build-system -debug-info-format --traits --allow-writing-to-directory --allow-network-connections --package)
    __swift_offer_flags_options 2

    # Offer option value completions
    case "${prev}" in
    '--package-path')
        __swift_add_completions -d
        return
        ;;
    '--cache-path')
        __swift_add_completions -d
        return
        ;;
    '--config-path')
        __swift_add_completions -d
        return
        ;;
    '--security-path')
        __swift_add_completions -d
        return
        ;;
    '--scratch-path')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdks-path')
        __swift_add_completions -d
        return
        ;;
    '--toolset')
        __swift_add_completions -o plusdirs -fX '!*.@(.json)'
        return
        ;;
    '--pkg-config-path')
        __swift_add_completions -d
        return
        ;;
    '--manifest-cache')
        return
        ;;
    '--netrc-file')
        __swift_add_completions -f
        return
        ;;
    '--resolver-fingerprint-checking')
        return
        ;;
    '--resolver-signing-entity-checking')
        return
        ;;
    '--default-registry-url')
        return
        ;;
    '--configuration'|'-c')
        __swift_add_completions -W 'debug'$'\n''release'
        return
        ;;
    '-Xcc')
        return
        ;;
    '-Xswiftc')
        return
        ;;
    '-Xlinker')
        return
        ;;
    '-Xcxx')
        return
        ;;
    '--triple')
        return
        ;;
    '--sdk')
        __swift_add_completions -d
        return
        ;;
    '--toolchain')
        __swift_add_completions -d
        return
        ;;
    '--swift-sdk')
        return
        ;;
    '--sanitize')
        __swift_add_completions -W 'address'$'\n''thread'$'\n''undefined'$'\n''scudo'$'\n''fuzzer'
        return
        ;;
    '--jobs'|'-j')
        return
        ;;
    '--explicit-target-dependency-import-check')
        __swift_add_completions -W 'none'$'\n''warn'$'\n''error'
        return
        ;;
    '--build-system')
        __swift_add_completions -W 'native'$'\n''swiftbuild'$'\n''xcode'
        return
        ;;
    '-debug-info-format')
        __swift_add_completions -W 'dwarf'$'\n''codeview'$'\n''none'
        return
        ;;
    '--traits')
        return
        ;;
    '--allow-writing-to-directory')
        return
        ;;
    '--allow-network-connections')
        __swift_add_completions -W 'none'$'\n''local(ports: [])'$'\n''all(ports: [])'$'\n''docker'$'\n''unixDomainSocket'
        return
        ;;
    '--package')
        return
        ;;
    esac
}

_swift_help() {
    :
}

complete -o filenames -F _swift swift
