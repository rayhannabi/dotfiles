# zoxide.nu

use ../modules/setup/zoxide.nu *

alias cd = z

if not ($env.ZOXIDE_INTEGRATION_PATH | path exists)  {
    setup zoxide
}
