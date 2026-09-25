# java.nu

$env.JAVA_HOME = match ($nu.os-info | get name) {
    macos => $"(/usr/libexec/java_home)"
    linux => "/usr/lib/jvm/default"
}
