# Jonsbo / TURZX LCD AIO on Linux

Working notes and ready-to-use files for getting a **Jonsbo / TURZX AIO LCD screen**
running on Linux using [`turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python).

The display shows up in Linux as:

```
1cbe:0035 Luminary Micro Inc. TURZX1.0
```

This is a small **800x480** USB LCD. Upstream did not detect it out of the box, so this
repo collects the one-line driver patch, a stable theme, a udev rule, and an autostart
script that together make it work.

> ⚠️ **Scope / honesty note.** This was tested with **one** Jonsbo / TURZX LCD device
> (`1cbe:0035`) on **Manjaro Linux**. It is not a claim of universal support for every
> Jonsbo or TURZX product. Other revisions may use different product IDs or resolutions.

> 📝 This is an **unofficial community setup**. It is **not affiliated with Jonsbo**,
> TURZX, or the `turing-smart-screen-python` project.

[Tiếng Việt / Vietnamese README →](README.vi.md)

---

## What's in this repo

```
jonsbo-turzx-lcd-linux/
├── README.md                       # this file (English)
├── README.vi.md                    # Vietnamese
├── setup-notes.md                  # exact working values + command summary
├── patches/
│   └── jonsbo-1cbe-0035.patch      # driver patch adding the 1cbe:0035 product ID
├── themes/
│   └── JonsboBlue800Stable/        # custom 800x480 theme
├── scripts/
│   └── start-jonsbo-lcd.sh         # launch script (used for autostart)
└── udev/
    └── 99-jonsbo-turzx-lcd.rules   # non-root USB access rule
```

---

## 1. Prerequisites (Manjaro Linux)

Install Python, git, and the Tk toolkit (needed by `configure.py`'s GUI):

```bash
sudo pacman -S --needed python python-pip git tk
```

> `tk` is easy to forget. Without it, `python configure.py` fails with a missing
> `tkinter` / Tk error. See [Troubleshooting](#troubleshooting).

---

## 2. Clone and set up `turing-smart-screen-python`

These instructions match the paths used by the autostart script in this repo
(`/home/dokuro/Downloads/turing-smart-screen-python`). Adjust them to your own home
directory / location as needed.

```bash
cd ~/Downloads
git clone https://github.com/mathoudebine/turing-smart-screen-python.git
cd turing-smart-screen-python

# Create an isolated virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

## 3. Detect the USB device with `lsusb`

Plug the LCD in and confirm Linux sees it:

```bash
lsusb | grep -i 1cbe
```

Expected output:

```
Bus 001 Device 002: ID 1cbe:0035 Luminary Micro Inc. TURZX1.0
```

The important part is the ID pair **`1cbe:0035`**:

- `1cbe` = vendor ID (already supported upstream)
- `0035` = product ID (the Jonsbo / TURZX panel — **not** recognized by stock upstream)

If you do not see the device at all, check the cable and USB header before continuing.

---

## 4. Apply the driver patch for `1cbe:0035`

Upstream `turing-smart-screen-python` did not know about product ID `0x0035`, so the
display was never found. The fix is to register it (and its 800x480 resolution) in the
driver's `PRODUCT_ID` map.

File patched:

```
library/lcd/lcd_comm_turing_usb.py
```

Change inside the `PRODUCT_ID` dictionary — add this entry:

```python
0x0035: (800, 480),  # Jonsbo/TURZX USB LCD
```

### Option A — apply the included patch

From inside the cloned repo:

```bash
cd ~/Downloads/turing-smart-screen-python
git apply /path/to/jonsbo-turzx-lcd-linux/patches/jonsbo-1cbe-0035.patch
```

If `git apply` complains (e.g. the upstream file changed since this was written), use:

```bash
patch -p1 < /path/to/jonsbo-turzx-lcd-linux/patches/jonsbo-1cbe-0035.patch
```

### Option B — edit by hand

Open `library/lcd/lcd_comm_turing_usb.py`, find the `PRODUCT_ID = { ... }` block, and
add the `0x0035: (800, 480),` line as the first entry. That's the whole change.

---

## 5. Install the theme

Copy the custom theme into the project's themes folder:

```bash
cp -r /path/to/jonsbo-turzx-lcd-linux/themes/JonsboBlue800Stable \
      ~/Downloads/turing-smart-screen-python/res/themes/JonsboBlue800Stable
```

`JonsboBlue800Stable` is adapted from upstream theme `26` for the 800x480 Jonsbo panel.
See [Known limitations](#known-limitations).

---

## 6. Working configuration

Edit `config.yaml` in the project root. The values confirmed working on this device:

```yaml
config:
  THEME: JonsboBlue800Stable
display:
  REVISION: TUR_USB
  DISPLAY_REVERSE: true
```

The full working `display:` block used here was:

```yaml
display:
  REVISION: TUR_USB
  BRIGHTNESS: 20
  DISPLAY_REVERSE: true
  RESET_ON_STARTUP: true
```

`DISPLAY_REVERSE: true` matters — without it the image can come out mirrored / wrong
side. See [Troubleshooting](#troubleshooting).

You can run `python configure.py` for the GUI configurator, or just edit `config.yaml`
directly with the values above.

---

## 7. udev rule (run without sudo)

By default the USB device is owned by root, so the app needs `sudo`. Install the udev
rule to grant your logged-in user access:

```bash
sudo cp /path/to/jonsbo-turzx-lcd-linux/udev/99-jonsbo-turzx-lcd.rules \
        /etc/udev/rules.d/99-jonsbo-turzx-lcd.rules

sudo udevadm control --reload-rules
sudo udevadm trigger
```

Then **unplug and replug** the LCD so the new rule applies.

The rule itself:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="1cbe", ATTR{idProduct}=="0035", MODE="0666", TAG+="uaccess"
```

---

## 8. Run it

```bash
cd ~/Downloads/turing-smart-screen-python
source .venv/bin/activate
python main.py
```

If the LCD lights up and shows CPU / GPU / RAM / disk stats, you're done.

---

## 9. GNOME autostart

To start the LCD automatically on login.

1. Install the launch script (adjust the path if your clone is elsewhere — the script
   has the full paths hard-coded inside it):

   ```bash
   mkdir -p ~/.local/bin
   cp /path/to/jonsbo-turzx-lcd-linux/scripts/start-jonsbo-lcd.sh ~/.local/bin/start-jonsbo-lcd.sh
   chmod +x ~/.local/bin/start-jonsbo-lcd.sh
   ```

   The script:

   ```bash
   #!/usr/bin/env bash
   cd /home/dokuro/Downloads/turing-smart-screen-python || exit 1
   exec /home/dokuro/Downloads/turing-smart-screen-python/.venv/bin/python \
        /home/dokuro/Downloads/turing-smart-screen-python/main.py
   ```

2. Create a GNOME autostart entry at
   `~/.config/autostart/jonsbo-lcd.desktop`:

   ```ini
   [Desktop Entry]
   Type=Application
   Name=Jonsbo LCD
   Exec=/home/dokuro/.local/bin/start-jonsbo-lcd.sh
   X-GNOME-Autostart-enabled=true
   Terminal=false
   ```

3. Log out and back in. The LCD should populate shortly after the desktop loads.

> Tip: GNOME's **Tweaks** app (`Startup Applications`) can also add the script through
> a GUI instead of writing the `.desktop` file by hand.

---

## Troubleshooting

**`python configure.py` fails with a missing Tk / `tkinter` error**
Install the Tk toolkit:

```bash
sudo pacman -S tk
```

**LCD reports "USB device not found" / nothing lights up**
The product ID patch is missing or didn't apply. Confirm
`library/lcd/lcd_comm_turing_usb.py` contains `0x0035: (800, 480)` inside `PRODUCT_ID`,
and that `lsusb | grep 1cbe` shows `1cbe:0035`.

**"Access denied" / permission errors on the USB device**
The udev rule isn't active. Re-check
`/etc/udev/rules.d/99-jonsbo-turzx-lcd.rules`, reload with
`sudo udevadm control --reload-rules && sudo udevadm trigger`, and replug the device.
As a quick test you can run with `sudo` — if it works under sudo, the problem is
permissions/udev.

**Image is duplicated, cut off, or mirrored**
Confirm both of these:
- the driver entry is exactly `0x0035: (800, 480)` (correct resolution), and
- `config.yaml` has `DISPLAY_REVERSE: true`.

---

## Known limitations

- The `JonsboBlue800Stable` theme is **stable and usable, but not pixel-perfect**. It
  was adapted from upstream theme `26` for the 800x480 panel; element placement and
  styling could still be polished.
- Only the `1cbe:0035` revision was tested. Other Jonsbo / TURZX panels may differ.
- Paths in the script and docs assume the clone lives at
  `~/Downloads/turing-smart-screen-python`. Change them to match your setup.

---

## Credits

- [`turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python)
  by [@mathoudebine](https://github.com/mathoudebine) and contributors — the upstream
  project that drives the display. All real driver work belongs to them.
- This repo only adds a small product-ID patch, a theme, and Linux glue (udev +
  autostart) for the Jonsbo / TURZX `1cbe:0035` panel.

## License / disclaimer

Provided as-is, for the community. Not affiliated with or endorsed by Jonsbo, TURZX, or
the upstream project. Refer to upstream for the library's own license.
