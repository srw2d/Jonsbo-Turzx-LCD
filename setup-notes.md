# Setup notes — Jonsbo / TURZX LCD (1cbe:0035)

Quick reference of the exact values that worked, plus a summary of the command history.
Tested on **Manjaro Linux** with a single Jonsbo / TURZX LCD reporting `1cbe:0035`.

## Exact working values

| Item | Value |
|------|-------|
| USB ID (`lsusb`) | `1cbe:0035 Luminary Micro Inc. TURZX1.0` |
| Vendor ID | `0x1cbe` |
| Product ID | `0x0035` |
| Resolution (portrait) | `800 x 480` |
| Patched file | `library/lcd/lcd_comm_turing_usb.py` |
| `PRODUCT_ID` entry added | `0x0035: (800, 480),  # Jonsbo/TURZX USB LCD` |
| Clone location | `/home/dokuro/Downloads/turing-smart-screen-python` |
| Virtualenv | `/home/dokuro/Downloads/turing-smart-screen-python/.venv` |
| Theme | `JonsboBlue800Stable` (adapted from upstream theme `26`) |
| Autostart script | `/home/dokuro/.local/bin/start-jonsbo-lcd.sh` |
| udev rule | `/etc/udev/rules.d/99-jonsbo-turzx-lcd.rules` |

### Driver patch (the one change that matters)

```python
PRODUCT_ID = {
    0x0035: (800, 480),  # Jonsbo/TURZX USB LCD
    0x0028: (480, 480),  # Turing 2.8" round (USB)
    ...
}
```

### config.yaml — working display block

```yaml
config:
  COM_PORT: AUTO
  THEME: JonsboBlue800Stable
  HW_SENSORS: AUTO
display:
  REVISION: TUR_USB
  BRIGHTNESS: 20
  DISPLAY_REVERSE: true
  RESET_ON_STARTUP: true
```

Minimum that must be set:

```yaml
THEME: JonsboBlue800Stable
REVISION: TUR_USB
DISPLAY_REVERSE: true
```

### udev rule

```
SUBSYSTEM=="usb", ATTR{idVendor}=="1cbe", ATTR{idProduct}=="0035", MODE="0666", TAG+="uaccess"
```

### Autostart script (`start-jonsbo-lcd.sh`)

The committed script is path-agnostic: it resolves the project dir from `$TURING_DIR`,
then `~/Downloads/turing-smart-screen-python`, then `~/turing-smart-screen-python`, and
prefers the project's `.venv`. Override without editing:

```bash
TURING_DIR=/opt/turing-smart-screen-python ~/.local/bin/start-jonsbo-lcd.sh
```

The original hard-coded equivalent (for reference) was:

```bash
#!/usr/bin/env bash
cd /home/dokuro/Downloads/turing-smart-screen-python || exit 1
exec /home/dokuro/Downloads/turing-smart-screen-python/.venv/bin/python \
     /home/dokuro/Downloads/turing-smart-screen-python/main.py
```

## Command history summary

```bash
# 1. Dependencies (Manjaro)
sudo pacman -S --needed python python-pip git tk

# 2. Clone + venv + deps
cd ~/Downloads
git clone https://github.com/mathoudebine/turing-smart-screen-python.git
cd turing-smart-screen-python
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3. Confirm the device is present
lsusb | grep -i 1cbe          # -> 1cbe:0035 ... TURZX1.0

# 4. Patch the driver: add 0x0035: (800, 480) to PRODUCT_ID
#    in library/lcd/lcd_comm_turing_usb.py

# 5. Install the theme
cp -r JonsboBlue800Stable res/themes/

# 6. Set config.yaml (REVISION: TUR_USB, DISPLAY_REVERSE: true, THEME: JonsboBlue800Stable)

# 7. Install udev rule, reload, replug
sudo cp 99-jonsbo-turzx-lcd.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# 8. Run
python main.py

# 9. Autostart: ~/.local/bin/start-jonsbo-lcd.sh + ~/.config/autostart/jonsbo-lcd.desktop
```

## Gotchas hit along the way

- `python configure.py` failed until `tk` was installed.
- Display not found until the `0x0035` product ID was added to the driver.
- Needed `DISPLAY_REVERSE: true` to get the image oriented correctly.
- Without the udev rule, the app needed `sudo` to access the device.
