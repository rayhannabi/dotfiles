# android.nu

use std/util "path add"

$env.ANDROID_HOME = ($env.HOME | path join Android/Sdk)

path add ($env.ANDROID_HOME | path join platform-tools)
path add ($env.ANDROID_HOME | path join tools)
path add ($env.ANDROID_HOME | path join tools/bin)
path add ($env.ANDROID_HOME | path join emulator)
path add ($env.ANDROID_HOME | path join cmdline-tools/latest/bin)
