fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios sync_certificates

```sh
[bundle exec] fastlane ios sync_certificates
```

Fetch or create certificates and profiles

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new release build to the App Store

### ios upload_ipa

```sh
[bundle exec] fastlane ios upload_ipa
```

Upload only the IPA to bypass metadata crashes

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload only the screenshots

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload only metadata

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
