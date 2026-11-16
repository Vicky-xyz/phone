# PhoneBox Windows installer (built by GitHub Actions)

Packages the official PhoneBox release (https://github.com/ersinkoc/phonebox) into one
`PhoneBox-Setup-<version>.exe`: the Windows agent, the phone APK, desktop and Start-menu
shortcuts, optional start with Windows, and an optional step that installs the APK on a
connected phone.

## Use
1. Push this repo to your own GitHub account.
2. Actions tab -> build-installer -> Run workflow. Leave "tag" empty for the latest PhoneBox
   release, or enter a tag (for example the version your phone already has).
3. Download `PhoneBox-Setup-<version>.exe` from the repo's Releases page (or the run's artifacts).

The installer is not code-signed, so Windows SmartScreen may warn: More info -> Run anyway.
