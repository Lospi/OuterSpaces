
<div align="center">
  <img
    src="OS-Logo.webp"
    alt="Outer Spaces"
  >
  <h1>
    Outer Spaces
  </h1>
  <p>
   A macOS menu bar app to change your current space according to your focus change.
  </p>
  <p>
    <a href="#features">Features</a> •
    <a href="#installation">Installation</a> •
    <a href="#permission-request">Permission Request</a> •
    <a href="#contributing">Contributing</a> •
    <a href="#languages">Languages</a> •
    <a href="#acknowledgement">Acknowledgement</a>
  </p>
</div>

Outer Spaces is a macOS application for switching your spaces according to your selected focus!

## Features

* Create presets for your focus
* Change your spaces automatically
* Toggle Stage Manager per preset settings
* Set a default preset when leaving focus

<div>
<img
    src="Example.webp"
    alt="Example animated image"
 >
 </div>

## Installation

Download the latest release from [this Github repository Releases page](https://github.com/Lospi/Outer-Spaces/releases).
Just drag the .app to the Application folder using the .dmg file.

## Permission Request

Outer Spaces requires two permissions: Accessibility and Automation. Make sure to enable both permissions within Privacy and Security on your macOS settings.

<div>
<img
    src="Settings.webp"
    alt="Settings image"
 >
 </div>

## Contributing

Feel free to share, open issues and contribute to this project! ❤️

## Languages

🇺🇸 English • 🇧🇷 Brazilian Portuguese

1.  Add a new Localization with Outer Spaces project Info settings
2.  Edit the **Localizable**  file with the proper translations

## Acknowledgement

This README file was heavily inspired by [Reminders MenuBar repository](https://github.com/DamascenoRafael/reminders-menubar) description.

## Building and validating Focus switching

Use the `Outer Spaces` scheme with a stable **Apple Development** signing identity
and your own development team. Keep the same bundle identifier and build location
between runs. A build with code signing disabled checks compilation only; it does
not validate macOS privacy permissions or Focus-filter registration.

1. Quit other copies of Outer Spaces before running the source build.
2. Launch the exact `.app` built by Xcode. In Privacy & Security, grant that app
   Accessibility and allow it to control **System Events** under Automation.
   If a rebuilt or differently signed copy is denied, remove the stale app entry
   and add the current build again. Do not reset all privacy permissions or disable SIP.
3. Enable the Mission Control shortcuts for the desktops in the preset. The app
   uses Control+1…9 for Desktop 1…9, Control+Option+0 for Desktop 10, and
   Control+Option+1…9 for Desktop 11…19. Configure these exact combinations for
   desktops beyond 9; remapped or disabled shortcuts cannot be inferred automatically.
4. Refresh Spaces, create a preset, and select it in System Settings → Focus →
   Focus Filters → Outer Spaces. If the app identity changed, reselect its filter.
5. Check a manual desktop switch, then toggle the configured Focus. Test permission
   denial and recovery separately for Accessibility and Automation. An accepted
   keyboard event now counts as success only after the target desktop is observed.
6. Check Focus deactivation with a saved default preset, then deny Focus Status
   access: unknown status must not repeatedly apply the default preset. An active
   mapped filter takes precedence over the shared notification-availability status.

PR verification uses the `Outer Spaces Tests` Swift Testing target. Its injected
switching and Focus dependencies do not send keystrokes or change real Focus modes.
Signed runtime checks are still required for permission recovery, shortcut mappings,
fullscreen desktops, and multiple displays. Issue #8's original signing/TCC cause
must not be considered reproduced solely because an unsigned build or unit test passes.
