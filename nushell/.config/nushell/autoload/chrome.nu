# chrome.nu

if ($nu.os-info | get name) == "linux" {
    $env.CHROME_EXECUTABLE = "google-chrome-stable"
}
