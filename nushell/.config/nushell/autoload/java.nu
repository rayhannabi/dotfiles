# java.nu

$env.JAVA_HOME = match ($nu.os-info | get name) {
    macos => (try { ^/usr/libexec/java_home | str trim } catch { null })
    linux => "/usr/lib/jvm/default"
    _ => null
}