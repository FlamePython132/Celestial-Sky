# Sky View — KDE Plasma Widget

A KDE Plasma 6 widget that displays the current positions of solar system bodies along the sky arc, with accurate rise/set times and a time slider for previewing past and future positions.

> **Work in progress** — this widget is still experimental and under active testing. Expect bugs and breaking changes.

---

## Features

- Displays the Sun, Moon, and all planets up to Neptune
- Accurate rise and set times via [astronomy-engine](https://github.com/cosinekitty/astronomy)
- Info panel showing rise/set times for currently visible objects
- Moon phase images
- Jupiter Great Red Spot rotation
- Saturn ring tilt
- Configurable location, planet size scale, and background opacity

---

## Requirements

- KDE Plasma 6
- Qt 6

---

## Installation

1. Copy the widget folder to:
   ```
   ~/.local/share/plasma/plasmoids/com.mate.skyview/
   ```

2. Install with:
   ```bash
   kpackagetool6 --type Plasma/Applet --install ~/.local/share/plasma/plasmoids/com.mate.skyview
   ```
   Or install Plasmoid:

3. Right-click your desktop or panel → **Add Widgets** → search **Sky View**

---

## Configuration

Right-click the widget → **Configure**:

| Setting | Description |
|---|---|
| Latitude | Your geographic latitude |
| Longitude | Your geographic longitude |
| Planet size | Global scale multiplier for all planet icons |
| Background opacity | 0 = fully transparent, 1 = fully opaque |

---

## Credits

- Astronomy calculations: [astronomy-engine](https://github.com/cosinekitty/astronomy) by Don Cross
