<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Nightwatchman icon">
</p>

# Nightwatchman

Keeps your Mac awake from the menu bar, also when the lid is closed.

- **One click.** Click the torch icon to keep the Mac awake. Click again to let it sleep.
- **Lid closed.** The Mac stays awake when you close the lid, on battery power and with no external
  display.
- **Durations.** Right-click the icon and choose **Activate for Duration**: from 5 minutes to
  5 hours, or indefinitely. You can add your own durations and set the default in Settings.
- **Battery limits.** The watch stops at a low battery level (20 % at first) and when Low Power Mode
  comes on.

Nightwatchman does the job of [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake), which
gave the idea. It is written again in Swift and adds the closed lid.

## Install

Needs a Mac with Apple silicon and macOS 26 or later.

With [Homebrew](https://brew.sh):

```sh
brew install --cask knorthfield/tap/nightwatchman
```

Or download `Nightwatchman.zip` from the
[latest release](https://github.com/knorthfield/nightwatchman/releases/latest), unzip it, and move
`Nightwatchman.app` to Applications.

## Use

- Click the icon to turn the watch on or off. The icon is bright while the Mac stays awake, and dimmed when the Mac can sleep.
- Right-click the icon, or click with Option or Control, to open the menu.
- The first time that you turn the watch on, macOS asks for an administrator. See
  [How it works](#how-it-works). If you cancel, the watch stays off.
- **Settings…** has: Open at Login, Activate on Launch, Allow Display Sleep, Quit When the Timer
  Ends, the durations, and the battery limits.
- Nightwatchman opens at login. To stop this, turn off **Open at Login** in Settings.

## How it works

macOS has one setting that stops all sleep, also with the lid closed: `pmset -a disablesleep 1`.
Only root can change it. The first time, Nightwatchman asks for an administrator and installs the
file `/etc/sudoers.d/nightwatchman`. This file lets your user run these two commands, and no others,
without a password:

```
/usr/bin/pmset -a disablesleep 0
/usr/bin/pmset -a disablesleep 1
```

While the watch is on, Nightwatchman also keeps the display on, unless **Allow Display Sleep** is on.

### Safety

A closed Mac that stays awake in a bag can get hot, and the battery goes down.

- Nightwatchman sets `disablesleep` back to 0 when the watch stops, when you quit, and when the
  timer ends.
- If Nightwatchman crashes or you force it to quit, a small watchdog process sets it back to 0
  in some seconds.
- The setting stays after a restart of the Mac. If the Mac restarts while the watch is on,
  Nightwatchman sets it back to 0 when it opens at login.
- While the watch is on, the **Sleep** command in the Apple menu does not work.
- All apps that run as your user can run the two commands above.
- Apple does not document `disablesleep`, and can change it.

To see the setting: `pmset -g | grep SleepDisabled`. To set it back yourself:
`sudo pmset -a disablesleep 0`.

### Uninstall

Click the torch icon to turn the watch off, right-click it and click **Quit Nightwatchman**. Then:

```sh
brew uninstall --zap --cask nightwatchman
```

`--zap` also removes the settings and the sudoers file. Without Homebrew, move the app to the
Trash, then:

```sh
sudo rm /etc/sudoers.d/nightwatchman
defaults delete com.krisnorthfield.Nightwatchman
```

## Build

```sh
brew install xcodegen
echo 'DEVELOPMENT_TEAM = <your team ID>' > Local.xcconfig
xcodegen generate
open Nightwatchman.xcodeproj
```

To run the tests:

```sh
./test.sh
```

## License

MIT. See [LICENSE](LICENSE).
