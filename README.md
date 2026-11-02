<!-- Language: English (source) -->
**English** · [Tiếng Việt](README.vi.md)

# Don't mind me

A KernelSU / APatch module for device integrity on Xiaomi HyperOS. It hides root from
apps, passes Play Integrity, spoofs build properties, and fixes delayed push
notifications. Everything is driven from one WebUI.

## Disclaimer (educational use only)

> [!CAUTION]
> This project is for educational and security research only. It shows how apps read
> Android device integrity signals (bootloader / verified boot state, Play Integrity,
> hardware key attestation, build properties) and how a privileged module can change
> what those apps see.
>
> Use it only on devices you own. Do not use it to commit fraud, gain unauthorised
> access, bypass protections you are not entitled to, or break any app's terms of
> service or the law.

> [!WARNING]
> This changes low level system behaviour and comes with no warranty. It can leave a
> device unbootable or get a device or account banned. You are responsible for how you
> use it.

## What it does

From one install you pick which apps see a clean device, set up Keystore attestation,
spoof firmware properties, and patch what Google Play Services reports. If a conflicting
module is already installed, it is disabled automatically.

The WebUI is plain HTML/CSS/JS with its own fonts. It opens in English and switches to
Vietnamese when the system language is Vietnamese.

## Features

- One list of target apps drives both hiding and attestation. By default a selected app
  is only blind to known root / manager apps (Magisk, KernelSU, APatch, LSPosed, Lucky
  Patcher, and so on) while ordinary apps stay visible. A "Stronger hiding" switch makes
  it blind to every user app instead, which can break cross app features like sharing.
- Six property spoof switches (system, fingerprint, UTC, date, OS patch level, vendor
  patch level), so each can be toggled to match what an app needs.
- Load a keybox `.xml` through the system file picker.
- Fetch the latest Pixel bulletin date and pin the attestation patch level.
- An ADB debugging switch and a MIUI / HyperOS push notification (FCM) fix.
- Cached attestation keys and the GMS / target app caches are cleared on every save and
  on install, so the next launch gets a fresh verdict.
- Timestamped, tagged logs for install and runtime.

## Requirements

- arm64 device, Android 10 or newer (API 29).
- KernelSU (Manager version code 10670 or higher) or APatch.
- Installed from the manager while booted. Recovery install is not supported.

## Install

1. Download `dont_mind_me.zip`.
2. Install it as a module in the KernelSU or APatch manager.
3. Reboot.
4. Open the module's WebUI from the manager.

## WebUI

| Tab | What it does |
| --- | --- |
| Apps | Pick the target apps that should see a clean device; toggle "Stronger hiding" to hide every user app instead of only root / manager apps. |
| Properties | The six property spoof switches. |
| Attestation | Keystore keybox and the security patch date. |
| System | ADB debugging and the Xiaomi notification fix. |

Changes on the Apps and Properties tabs are staged. Press Save, then Reboot to apply.

## Logs

- `install.log` is written in the module directory during installation.
- `dont_mind_me.log` is written at boot and runtime by the boot scripts (post-fs-data,
  service, property spoof, notification fix), with timestamps and a per-script tag.

## Building from source

On Windows (PowerShell):

```powershell
.\build.ps1
```

This produces `out/dont_mind_me.zip`. The `hbd` wake-alarm helper (notification fix) is
built separately from [`notify/hbd.c`](notify/hbd.c); the compiled `bin/hbd` is committed.

## Credits

- Hide My Applist (OSS), per-app visibility: <https://github.com/frknkrc44/HMA-OSS>
- Tricky Store (OSS), Keystore / key attestation: <https://github.com/beakthoven/TrickyStoreOSS>
  (fork of the original [Tricky Store](https://github.com/5ec1cff/TrickyStore))
- NoMount, mountless module hiding: <https://github.com/maxsteeel/nomount>
- Tricky Addon: Update Target List, verified boot reset and target-list WebUI reference:
  <https://github.com/KOWX712/Tricky-Addon-Update-Target-List>
- ReZygisk, Zygisk runtime and boot-completed hook: <https://github.com/PerformanC/ReZygisk>
- PlayIntegrityFork, Play Integrity research: <https://github.com/osm0sis/PlayIntegrityFork>

## License

GNU General Public License v3.0, see [LICENSE](LICENSE). Because it includes
GPL-licensed components, the combined work is distributed under GPL-3.0.
