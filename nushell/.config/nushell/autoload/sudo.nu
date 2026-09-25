# sudo.nu

use ../modules/term.nu

$env.SUDO_PROMPT = if (term is-nice) {
    "🔑 Password (%u@%h): "
} else {
    "# Password (%u@%h): "
}
