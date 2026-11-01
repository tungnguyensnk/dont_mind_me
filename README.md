<!-- Language: English (source) -->
**English** · [Tiếng Việt](README.vi.md)

# Don't mind me

One KernelSU / APatch module for the whole device‑integrity workflow.

---

## ⚠️ Disclaimer — educational use only

> [!CAUTION]
> **This project is provided strictly for educational and security‑research purposes.**
> It demonstrates how Android device‑integrity signals — bootloader / verified‑boot
> state, Play Integrity, hardware key attestation and build properties — are read by
> applications, and how a privileged module can change what those applications observe.
>
> Use it **only on devices you own and control**, to learn and to study platform
> security. Do **not** use it to commit fraud, to gain unauthorised access, to evade
> protections you are not entitled to bypass, or to violate the terms of service of any
> application or any applicable law.

> [!WARNING]
> This software alters low‑level system behaviour and is provided **without any
> warranty**. It may leave a device unbootable or get a device or account banned.
> **You alone are responsible for how you use it.**

---

## Overview

**Don't mind me** gives your apps a clean, consistent view of your device and keeps it
that way — from one module, through one WebUI, with no config files to hand‑edit.

A single install covers the whole workflow: choosing which apps see a clean device,
shaping Keystore attestation, spoofing firmware properties and patching Google Play
Services. Any conflicting module already on the device is disabled automatically, so
there is nothing to stack or reconcile — **one module is enough.**

The WebUI is written in plain HTML/CSS/JS, ships with its own fonts, follows a warm
light theme, and is bilingual: it starts in **English** and switches to **Vietnamese**
automatically when the system language is Vietnamese.

## Features

- **One module, everything covered.** App visibility, Keystore attestation, property
  spoofing and the Play Services patch all work from a single install — no stacking
  separate modules, and any conflicting one already present is disabled automatically.
- **Target apps.** One list drives both the visibility engine and the attestation
  targets — tick the apps that should see a clean device. By default each selected app
  is only blind to known root / manager apps (Magisk, KernelSU, APatch, LSPosed, Lucky
  Patcher…), while ordinary apps stay visible; a **Stronger hiding** switch instead makes
  it blind to every user app, at the cost of cross‑app features like sharing.
- **Property spoofing.** Six independent switches (system, fingerprint, UTC, date,
  OS patch level, vendor patch level) so each can be toggled to find exactly what an
  app needs.
- **Keystore keybox.** Pick a keybox `.xml` through the system file picker and apply it.
- **Security patch date.** Fetch the latest Pixel bulletin date and pin the attestation
  patch level.
- **System toggles.** ADB debugging switch and a MIUI / HyperOS notification (FCM) fix.
- **Fresh verdicts.** Cached attestation keys and the GMS / target‑app caches are
  cleared on every save *and* on install, so the next launch fetches a fresh verdict.
- **Debuggable.** Timestamped, tagged logs for both install and runtime.

## Requirements

- **arm64** device, **Android 10+** (API 29).
- **KernelSU** (Manager version code ≥ 10670) **or APatch**.
- Installed from the manager while booted (recovery install is not supported).

## Installation

1. Download `dont_mind_me.zip`.
2. In the KernelSU or APatch manager, install it as a module.
3. Reboot.
4. Open the module's **WebUI** from the manager.

## Using the WebUI

The WebUI has four tabs:

| Tab | What it does |
| --- | --- |
| **Apps** | Pick the target apps that should see a clean device; toggle **Stronger hiding** to hide every user app instead of only root / manager apps. |
| **Properties** | Toggle the six property‑spoof switches. |
| **Attestation** | Set the Keystore keybox and the security‑patch date. |
| **System** | Toggle ADB debugging and the Xiaomi notification fix. |

Changes on the **Apps** and **Properties** tabs are staged; press **Save**, then
**Reboot** to apply them.

## Logs & debugging

- `install.log` — written in the module directory during installation.
- `dont_mind_me.log` — written at boot/runtime by the boot scripts (post‑fs‑data,
  service, property spoof, notification fix), with timestamps and a per‑script tag.

## Building from source

On Windows (PowerShell):

```powershell
.\build.ps1
```

This produces `out/dont_mind_me.zip`. The native Google Play Services patch lives in
[`gms/src`](gms/src) and is built separately; the compiled artifacts are checked in.

## Acknowledgements

Built with the help of these open‑source projects — thanks to their authors and
maintainers:

- **Hide My Applist (OSS)** — per‑app visibility engine — <https://github.com/frknkrc44/HMA-OSS>
- **Tricky Store (OSS)** — Keystore / key‑attestation layer — <https://github.com/beakthoven/TrickyStoreOSS>
  (fork of the original [Tricky Store](https://github.com/5ec1cff/TrickyStore))
- **NoMount** — mountless module hiding driver — <https://github.com/maxsteeel/nomount>
- **Tricky Addon: Update Target List** — verified‑boot property reset and target‑list
  WebUI reference — <https://github.com/KOWX712/Tricky-Addon-Update-Target-List>
- **ReZygisk** — Zygisk runtime and boot‑completed hook pattern — <https://github.com/PerformanC/ReZygisk>
- **PlayIntegrityFork** — Play Integrity / device‑property research — <https://github.com/osm0sis/PlayIntegrityFork>

## License

Licensed under the **GNU General Public License v3.0**. See [LICENSE](LICENSE).
Because it incorporates GPL‑licensed components, the combined work is distributed
under the GPL‑3.0.
