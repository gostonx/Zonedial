# Zonedial

A lightweight macOS menu bar app for tracking time across multiple time zones at a glance.

![Zonedial demo](assets/demo.gif)

## Download

[![Download](https://img.shields.io/badge/Download-v1.0.1-blue)](https://github.com/gostonx/Zonedial/releases/latest/download/Zonedial.dmg)

> Requires macOS 14.0+

## Features

- **Live clock** — updates every second with your local time
- **Multiple time zones** — add any city or country and see its current time instantly
- **12H / 24H / Seconds** — toggle time formats in one click
- **Add/Subtract mode** — shift all times by hours or minutes to compare against a target
- **Favorites** — star frequently-used time zones so they stay on top
- **Drag to reorder** — arrange time zones in any order
- **Dayshift labels** — highlights "Tomorrow" or "Yesterday" when a zone crosses midnight
- **Global hotkey** — press `Cmd+Shift+Z` from anywhere to open the panel
- **Launch at Login** — built-in option, no extra setup

## Install

### Homebrew

```bash
brew tap gostonx/zonedial
brew install --cask zonedial
```

### Manual

1. Download `Zonedial.dmg` from the [latest release](https://github.com/gostonx/Zonedial/releases/latest)
2. Open the DMG and drag **Zonedial** into `/Applications`
3. Right-click the app and choose **Open** (required on first launch since it's not notarized)
4. Click the deskclock icon in your menu bar

## Build from Source

```bash
git clone https://github.com/gostonx/Zonedial.git
cd Zonedial
open Zonedial.xcodeproj
```

Select **Product > Archive** in Xcode, then export as a `.app` or package into a DMG.
