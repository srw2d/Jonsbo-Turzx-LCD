# Màn hình LCD AIO Jonsbo / TURZX trên Linux

Ghi chú và các tệp dùng-được-ngay để chạy **màn hình LCD AIO Jonsbo / TURZX** trên
Linux bằng [`turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python).

Màn hình hiển thị trong Linux dưới dạng:

```
1cbe:0035 Luminary Micro Inc. TURZX1.0
```

Đây là một màn hình LCD USB nhỏ **800x480**. Dự án gốc không nhận diện được nó ngay từ
đầu, nên repo này gom lại bản vá driver một dòng, một theme ổn định, một quy tắc udev,
và một script tự khởi động — tất cả cùng nhau giúp nó hoạt động.

> ⚠️ **Phạm vi / lời nói thật.** Cấu hình này đã được kiểm thử với **một** thiết bị LCD
> Jonsbo / TURZX (`1cbe:0035`) trên **Manjaro Linux**. Đây **không** phải là lời khẳng
> định hỗ trợ phổ quát cho mọi sản phẩm Jonsbo hay TURZX. Các phiên bản khác có thể dùng
> product ID hoặc độ phân giải khác.

> 📝 Đây là một **cấu hình cộng đồng không chính thức**. Nó **không liên kết với Jonsbo**,
> TURZX, hay dự án `turing-smart-screen-python`.

[English README →](README.md)

---

## Repo này có gì

```
jonsbo-turzx-lcd-linux/
├── README.md                       # tiếng Anh
├── README.vi.md                    # tệp này (tiếng Việt)
├── setup-notes.md                  # giá trị hoạt động chính xác + tóm tắt lệnh
├── patches/
│   └── jonsbo-1cbe-0035.patch      # bản vá driver thêm product ID 1cbe:0035
├── themes/
│   └── JonsboBlue800Stable/        # theme 800x480 tùy chỉnh
├── scripts/
│   └── start-jonsbo-lcd.sh         # script khởi chạy (dùng cho autostart)
└── udev/
    └── 99-jonsbo-turzx-lcd.rules   # quy tắc truy cập USB không cần root
```

---

## 1. Yêu cầu trước (Manjaro Linux)

Cài Python, git và bộ công cụ Tk (cần cho giao diện của `configure.py`):

```bash
sudo pacman -S --needed python python-pip git tk
```

> Gói `tk` rất dễ quên. Thiếu nó, `python configure.py` sẽ lỗi do thiếu `tkinter` / Tk.
> Xem mục [Khắc phục sự cố](#khắc-phục-sự-cố).

---

## 2. Tải về và cài đặt `turing-smart-screen-python`

Các bước dưới đây khớp với đường dẫn mà script autostart trong repo này dùng
(`/home/dokuro/Downloads/turing-smart-screen-python`). Hãy đổi cho phù hợp với thư mục
home / vị trí của bạn.

```bash
cd ~/Downloads
git clone https://github.com/mathoudebine/turing-smart-screen-python.git
cd turing-smart-screen-python

# Tạo môi trường ảo riêng
python -m venv .venv
source .venv/bin/activate

# Cài các thư viện phụ thuộc
pip install -r requirements.txt
```

---

## 3. Phát hiện thiết bị USB bằng `lsusb`

Cắm LCD vào và xác nhận Linux thấy nó:

```bash
lsusb | grep -i 1cbe
```

Kết quả mong đợi:

```
Bus 001 Device 002: ID 1cbe:0035 Luminary Micro Inc. TURZX1.0
```

Phần quan trọng là cặp ID **`1cbe:0035`**:

- `1cbe` = vendor ID (đã được hỗ trợ sẵn)
- `0035` = product ID (tấm nền Jonsbo / TURZX — **không** được bản gốc nhận diện)

Nếu không thấy thiết bị, hãy kiểm tra cáp và cổng USB trước khi tiếp tục.

---

## 4. Áp dụng bản vá driver cho `1cbe:0035`

Bản gốc `turing-smart-screen-python` không biết product ID `0x0035`, nên không bao giờ
tìm thấy màn hình. Cách sửa là khai báo nó (và độ phân giải 800x480) trong từ điển
`PRODUCT_ID` của driver.

Tệp được vá:

```
library/lcd/lcd_comm_turing_usb.py
```

Thay đổi bên trong từ điển `PRODUCT_ID` — thêm dòng này:

```python
0x0035: (800, 480),  # Jonsbo/TURZX USB LCD
```

### Cách A — dùng bản vá kèm theo

Từ trong repo đã clone:

```bash
cd ~/Downloads/turing-smart-screen-python
git apply /đường/dẫn/tới/jonsbo-turzx-lcd-linux/patches/jonsbo-1cbe-0035.patch
```

Nếu `git apply` báo lỗi (ví dụ tệp gốc đã thay đổi so với lúc viết), dùng:

```bash
patch -p1 < /đường/dẫn/tới/jonsbo-turzx-lcd-linux/patches/jonsbo-1cbe-0035.patch
```

### Cách B — sửa bằng tay

Mở `library/lcd/lcd_comm_turing_usb.py`, tìm khối `PRODUCT_ID = { ... }`, và thêm dòng
`0x0035: (800, 480),` làm mục đầu tiên. Đó là toàn bộ thay đổi.

---

## 5. Cài theme

Sao chép theme tùy chỉnh vào thư mục themes của dự án:

```bash
cp -r /đường/dẫn/tới/jonsbo-turzx-lcd-linux/themes/JonsboBlue800Stable \
      ~/Downloads/turing-smart-screen-python/res/themes/JonsboBlue800Stable
```

`JonsboBlue800Stable` được chỉnh từ theme `26` của bản gốc cho tấm nền Jonsbo 800x480.
Xem [Hạn chế đã biết](#hạn-chế-đã-biết).

---

## 6. Cấu hình hoạt động

Sửa `config.yaml` ở thư mục gốc dự án. Các giá trị đã xác nhận chạy được trên thiết bị
này:

```yaml
config:
  THEME: JonsboBlue800Stable
display:
  REVISION: TUR_USB
  DISPLAY_REVERSE: true
```

Khối `display:` đầy đủ đã dùng ở đây là:

```yaml
display:
  REVISION: TUR_USB
  BRIGHTNESS: 20
  DISPLAY_REVERSE: true
  RESET_ON_STARTUP: true
```

`DISPLAY_REVERSE: true` rất quan trọng — thiếu nó hình có thể bị lật / sai chiều. Xem
[Khắc phục sự cố](#khắc-phục-sự-cố).

Bạn có thể chạy `python configure.py` để dùng giao diện cấu hình, hoặc sửa trực tiếp
`config.yaml` với các giá trị trên.

---

## 7. Quy tắc udev (chạy không cần sudo)

Mặc định thiết bị USB thuộc quyền root, nên ứng dụng cần `sudo`. Cài quy tắc udev để cấp
quyền cho người dùng đang đăng nhập:

```bash
sudo cp /đường/dẫn/tới/jonsbo-turzx-lcd-linux/udev/99-jonsbo-turzx-lcd.rules \
        /etc/udev/rules.d/99-jonsbo-turzx-lcd.rules

sudo udevadm control --reload-rules
sudo udevadm trigger
```

Sau đó **rút và cắm lại** LCD để quy tắc mới có hiệu lực.

Nội dung quy tắc:

```
SUBSYSTEM=="usb", ATTR{idVendor}=="1cbe", ATTR{idProduct}=="0035", MODE="0666", TAG+="uaccess"
```

---

## 8. Chạy thử

```bash
cd ~/Downloads/turing-smart-screen-python
source .venv/bin/activate
python main.py
```

Nếu LCD sáng lên và hiển thị các chỉ số CPU / GPU / RAM / ổ đĩa, là xong.

---

## 9. Tự khởi động trên GNOME

Để LCD tự chạy khi đăng nhập.

1. Cài script khởi chạy (đổi đường dẫn nếu clone ở nơi khác — script có đường dẫn đầy đủ
   ghi cứng bên trong):

   ```bash
   mkdir -p ~/.local/bin
   cp /đường/dẫn/tới/jonsbo-turzx-lcd-linux/scripts/start-jonsbo-lcd.sh ~/.local/bin/start-jonsbo-lcd.sh
   chmod +x ~/.local/bin/start-jonsbo-lcd.sh
   ```

   Nội dung script:

   ```bash
   #!/usr/bin/env bash
   cd /home/dokuro/Downloads/turing-smart-screen-python || exit 1
   exec /home/dokuro/Downloads/turing-smart-screen-python/.venv/bin/python \
        /home/dokuro/Downloads/turing-smart-screen-python/main.py
   ```

2. Tạo mục autostart cho GNOME tại
   `~/.config/autostart/jonsbo-lcd.desktop`:

   ```ini
   [Desktop Entry]
   Type=Application
   Name=Jonsbo LCD
   Exec=/home/dokuro/.local/bin/start-jonsbo-lcd.sh
   X-GNOME-Autostart-enabled=true
   Terminal=false
   ```

3. Đăng xuất rồi đăng nhập lại. LCD sẽ hiển thị dữ liệu ngay sau khi desktop tải xong.

> Mẹo: Ứng dụng **Tweaks** của GNOME (`Startup Applications`) cũng có thể thêm script
> bằng giao diện thay vì viết tệp `.desktop` bằng tay.

---

## Khắc phục sự cố

**`python configure.py` lỗi do thiếu Tk / `tkinter`**
Cài bộ công cụ Tk:

```bash
sudo pacman -S tk
```

**LCD báo "USB device not found" / không sáng**
Bản vá product ID bị thiếu hoặc chưa được áp dụng. Kiểm tra
`library/lcd/lcd_comm_turing_usb.py` có chứa `0x0035: (800, 480)` trong `PRODUCT_ID`
không, và `lsusb | grep 1cbe` có hiện `1cbe:0035` không.

**Lỗi "Access denied" / quyền truy cập USB**
Quy tắc udev chưa hoạt động. Kiểm tra lại
`/etc/udev/rules.d/99-jonsbo-turzx-lcd.rules`, nạp lại bằng
`sudo udevadm control --reload-rules && sudo udevadm trigger`, rồi cắm lại thiết bị.
Để thử nhanh, bạn có thể chạy bằng `sudo` — nếu chạy được dưới sudo thì vấn đề là
quyền/udev.

**Hình bị nhân đôi, bị cắt, hoặc bị lật**
Kiểm tra cả hai điều sau:
- mục driver phải đúng là `0x0035: (800, 480)` (đúng độ phân giải), và
- `config.yaml` có `DISPLAY_REVERSE: true`.

---

## Hạn chế đã biết

- Theme `JonsboBlue800Stable` **ổn định và dùng được, nhưng chưa hoàn hảo từng pixel**.
  Nó được chỉnh từ theme `26` của bản gốc cho tấm nền 800x480; vị trí và kiểu dáng các
  thành phần vẫn có thể được trau chuốt thêm.
- Chỉ phiên bản `1cbe:0035` được kiểm thử. Các tấm nền Jonsbo / TURZX khác có thể khác.
- Đường dẫn trong script và tài liệu giả định clone nằm ở
  `~/Downloads/turing-smart-screen-python`. Hãy đổi cho khớp với máy bạn.

---

## Ghi công

- [`turing-smart-screen-python`](https://github.com/mathoudebine/turing-smart-screen-python)
  của [@mathoudebine](https://github.com/mathoudebine) và những người đóng góp — dự án
  gốc điều khiển màn hình. Mọi công sức driver thực sự thuộc về họ.
- Repo này chỉ thêm một bản vá product-ID nhỏ, một theme, và phần kết nối cho Linux
  (udev + autostart) cho tấm nền Jonsbo / TURZX `1cbe:0035`.

## Giấy phép / miễn trừ

Cung cấp nguyên trạng, cho cộng đồng. Không liên kết hay được chứng thực bởi Jonsbo,
TURZX, hay dự án gốc. Xem dự án gốc để biết giấy phép của thư viện.
