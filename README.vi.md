[English](README.md) · **Tiếng Việt**

# Don't mind me

Một module KernelSU / APatch cho toàn bộ quy trình device‑integrity.

---

## ⚠️ Miễn trừ trách nhiệm — chỉ dùng cho mục đích giáo dục

> [!CAUTION]
> **Dự án này chỉ phục vụ mục đích giáo dục và nghiên cứu bảo mật.**
> Nó minh hoạ cách các tín hiệu device‑integrity của Android — trạng thái bootloader /
> verified‑boot, Play Integrity, hardware key attestation và các build property — được
> ứng dụng đọc, và cách một module đặc quyền có thể thay đổi những gì ứng dụng nhìn thấy.
>
> Chỉ dùng **trên thiết bị do chính bạn sở hữu và kiểm soát**, để học và nghiên cứu bảo
> mật nền tảng. **Không** dùng để gian lận, truy cập trái phép, né tránh các cơ chế bảo
> vệ mà bạn không có quyền vượt qua, hay vi phạm điều khoản sử dụng của bất kỳ ứng dụng
> nào hoặc pháp luật hiện hành.

> [!WARNING]
> Phần mềm này thay đổi hành vi hệ thống ở mức thấp và được cung cấp **không kèm bảo
> hành**. Nó có thể khiến thiết bị không khởi động được hoặc khiến thiết bị / tài khoản
> bị khoá. **Bạn tự chịu hoàn toàn trách nhiệm về cách mình sử dụng.**

---

## Giới thiệu

**Don't mind me** giúp các ứng dụng nhìn thấy một thiết bị "sạch" và nhất quán, và giữ
nguyên như vậy — từ một module duy nhất, qua một WebUI, không phải sửa file cấu hình.

Chỉ cần cài một lần là lo trọn quy trình: chọn app nào cần thấy thiết bị "sạch", chỉnh
lớp attestation Keystore, spoof thuộc tính firmware và vá Google Play Services. Mọi
module xung đột sẵn có trên máy sẽ bị tự tắt, nên không phải chồng nhiều công cụ hay xử
lý trùng lặp — **một module là đủ.**

WebUI viết bằng HTML/CSS/JS thuần, kèm sẵn font riêng, dùng tông sáng ấm, và song ngữ:
mặc định **tiếng Anh**, tự chuyển sang **tiếng Việt** khi ngôn ngữ hệ thống là tiếng Việt.

## Tính năng

- **Một module, lo đủ mọi thứ.** Ẩn ứng dụng theo app, attestation Keystore, spoof
  thuộc tính và vá Play Services đều chạy từ một lần cài — không phải chồng nhiều module,
  và mọi module xung đột sẵn có sẽ bị tự tắt.
- **Ứng dụng mục tiêu.** Một danh sách duy nhất điều khiển cả engine ẩn ứng dụng lẫn
  danh sách mục tiêu attestation — tick những app cần thấy một thiết bị "sạch". Mặc định
  mỗi app đã chọn chỉ bị ẩn nhóm app root / manager (Magisk, KernelSU, APatch, LSPosed,
  Lucky Patcher…), các app bình thường vẫn hiện; công tắc **Ẩn mạnh mẽ hơn** sẽ ẩn mọi
  app người dùng khỏi app đó, đổi lại các tính năng liên app như chia sẻ có thể bị ảnh hưởng.
- **Spoof thuộc tính.** Sáu công tắc độc lập (system, fingerprint, UTC, date, OS patch
  level, vendor patch level) để bật/tắt từng cái và tìm đúng thứ một app cần.
- **Keybox Keystore.** Chọn file keybox `.xml` qua trình chọn file hệ thống rồi áp dụng.
- **Ngày bản vá bảo mật.** Lấy ngày bản tin Pixel mới nhất và ghim mức patch cho
  attestation.
- **Công tắc hệ thống.** Bật/tắt ADB debugging và bản fix thông báo (FCM) cho MIUI /
  HyperOS.
- **Verdict mới.** Cache key attestation cùng cache của GMS / app mục tiêu được xoá mỗi
  lần Lưu *và* khi cài, để lần mở sau lấy verdict mới.
- **Dễ debug.** Log có timestamp và tag cho cả lúc cài lẫn lúc chạy.

## Yêu cầu

- Thiết bị **arm64**, **Android 10+** (API 29).
- **KernelSU** (Manager version code ≥ 10670) **hoặc APatch**.
- Cài từ manager khi máy đang chạy (không hỗ trợ cài từ recovery).

## Cài đặt

1. Tải `dont_mind_me.zip`.
2. Trong KernelSU hoặc APatch manager, cài như một module.
3. Khởi động lại.
4. Mở **WebUI** của module từ manager.

## Dùng WebUI

WebUI có bốn tab:

| Tab | Chức năng |
| --- | --- |
| **Ứng dụng** | Chọn các app mục tiêu cần thấy một thiết bị "sạch"; bật **Ẩn mạnh mẽ hơn** để ẩn mọi app người dùng thay vì chỉ ẩn nhóm app root / manager. |
| **Thông số** | Bật/tắt sáu công tắc spoof thuộc tính. |
| **Chứng thực** | Đặt keybox Keystore và ngày bản vá bảo mật. |
| **Hệ thống** | Bật/tắt ADB debugging và fix thông báo Xiaomi. |

Thay đổi ở tab **Ứng dụng** và **Thông số** được giữ tạm; nhấn **Lưu**, rồi **Khởi động
lại** để áp dụng.

## Log & debug

- `install.log` — ghi trong thư mục module lúc cài đặt.
- `dont_mind_me.log` — ghi lúc boot/chạy bởi các script boot (post‑fs‑data, service,
  spoof thuộc tính, fix thông báo), kèm timestamp và tag theo từng script.

## Build từ source

Trên Windows (PowerShell):

```powershell
.\build.ps1
```

Lệnh này tạo `out/dont_mind_me.zip`. Trình `hbd` (hẹn giờ cho fix thông báo) được build
riêng từ [`notify/hbd.c`](notify/hbd.c); bản đã biên dịch `bin/hbd` được commit sẵn.

## Ghi nhận

Thực hiện với sự trợ giúp của các dự án mã nguồn mở sau — cảm ơn các tác giả và người
duy trì:

- **Hide My Applist (OSS)** — engine ẩn ứng dụng theo app — <https://github.com/frknkrc44/HMA-OSS>
- **Tricky Store (OSS)** — lớp Keystore / key‑attestation — <https://github.com/beakthoven/TrickyStoreOSS>
  (fork từ [Tricky Store](https://github.com/5ec1cff/TrickyStore) gốc)
- **NoMount** — driver ẩn module kiểu mountless — <https://github.com/maxsteeel/nomount>
- **Tricky Addon: Update Target List** — nguồn tham khảo cho phần reset thuộc tính
  verified‑boot và WebUI danh sách mục tiêu — <https://github.com/KOWX712/Tricky-Addon-Update-Target-List>
- **ReZygisk** — runtime Zygisk và mẫu hook boot‑completed — <https://github.com/PerformanC/ReZygisk>
- **PlayIntegrityFork** — nghiên cứu Play Integrity / thuộc tính thiết bị — <https://github.com/osm0sis/PlayIntegrityFork>

## Giấy phép

Phát hành theo **GNU General Public License v3.0**. Xem [LICENSE](LICENSE). Do có sử dụng
các thành phần giấy phép GPL, toàn bộ tác phẩm kết hợp được phân phối theo GPL‑3.0.
