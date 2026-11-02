[English](README.md) · **Tiếng Việt**

# Don't mind me

Một module KernelSU / APatch lo device integrity trên Xiaomi HyperOS. Nó ẩn root khỏi
ứng dụng, qua Play Integrity, spoof build property, và fix thông báo đẩy bị trễ. Tất cả
điều khiển từ một WebUI.

## Miễn trừ trách nhiệm (chỉ dùng cho mục đích giáo dục)

> [!CAUTION]
> Dự án này chỉ phục vụ mục đích giáo dục và nghiên cứu bảo mật. Nó cho thấy cách ứng
> dụng đọc các tín hiệu device integrity của Android (trạng thái bootloader / verified
> boot, Play Integrity, hardware key attestation, build property) và cách một module đặc
> quyền có thể thay đổi những gì ứng dụng nhìn thấy.
>
> Chỉ dùng trên thiết bị do chính bạn sở hữu. Không dùng để gian lận, truy cập trái phép,
> né tránh các cơ chế bảo vệ mà bạn không có quyền vượt qua, hay vi phạm điều khoản sử
> dụng của ứng dụng hoặc pháp luật.

> [!WARNING]
> Phần mềm này thay đổi hành vi hệ thống ở mức thấp và không kèm bảo hành. Nó có thể khiến
> thiết bị không khởi động được, hoặc khiến thiết bị / tài khoản bị khoá. Bạn tự chịu trách
> nhiệm về cách mình sử dụng.

## Làm được gì

Chỉ cần cài một lần: chọn app nào cần thấy thiết bị "sạch", chỉnh lớp attestation Keystore,
spoof thuộc tính firmware, và vá những gì Google Play Services báo cáo. Nếu trên máy đã có
module xung đột, nó sẽ bị tự tắt.

WebUI viết bằng HTML/CSS/JS thuần, kèm font riêng. Mặc định mở tiếng Anh, tự chuyển sang
tiếng Việt khi ngôn ngữ hệ thống là tiếng Việt.

## Tính năng

- Một danh sách app mục tiêu điều khiển cả phần ẩn lẫn phần attestation. Mặc định app đã
  chọn chỉ bị ẩn nhóm app root / manager (Magisk, KernelSU, APatch, LSPosed, Lucky
  Patcher...), các app bình thường vẫn hiện. Công tắc "Ẩn mạnh mẽ hơn" sẽ ẩn mọi app người
  dùng khỏi app đó, đổi lại các tính năng liên app như chia sẻ có thể bị ảnh hưởng.
- Sáu công tắc spoof thuộc tính (system, fingerprint, UTC, date, OS patch level, vendor
  patch level), bật/tắt từng cái để tìm đúng thứ một app cần.
- Chọn file keybox `.xml` qua trình chọn file hệ thống.
- Lấy ngày bản tin Pixel mới nhất và ghim mức patch cho attestation.
- Công tắc ADB debugging và bản fix thông báo đẩy (FCM) cho MIUI / HyperOS.
- Cache key attestation cùng cache của GMS / app mục tiêu được xoá mỗi lần Lưu và khi cài,
  để lần mở sau lấy verdict mới.
- Log có timestamp và tag cho cả lúc cài lẫn lúc chạy.

## Yêu cầu

- Thiết bị arm64, Android 10 trở lên (API 29).
- KernelSU (Manager version code 10670 trở lên) hoặc APatch.
- Cài từ manager khi máy đang chạy. Không hỗ trợ cài từ recovery.

## Cài đặt

1. Tải `dont_mind_me.zip`.
2. Trong KernelSU hoặc APatch manager, cài như một module.
3. Khởi động lại.
4. Mở WebUI của module từ manager.

## WebUI

| Tab | Chức năng |
| --- | --- |
| Ứng dụng | Chọn các app mục tiêu cần thấy thiết bị "sạch"; bật "Ẩn mạnh mẽ hơn" để ẩn mọi app người dùng thay vì chỉ ẩn nhóm app root / manager. |
| Thông số | Sáu công tắc spoof thuộc tính. |
| Chứng thực | Keybox Keystore và ngày bản vá bảo mật. |
| Hệ thống | ADB debugging và fix thông báo Xiaomi. |

Thay đổi ở tab Ứng dụng và Thông số được giữ tạm; nhấn Lưu, rồi Khởi động lại để áp dụng.

## Log

- `install.log` ghi trong thư mục module lúc cài đặt.
- `dont_mind_me.log` ghi lúc boot và chạy bởi các script boot (post-fs-data, service,
  spoof thuộc tính, fix thông báo), kèm timestamp và tag theo từng script.

## Build từ source

Trên Windows (PowerShell):

```powershell
.\build.ps1
```

Lệnh này tạo `out/dont_mind_me.zip`. Trình `hbd` (hẹn giờ cho fix thông báo) được build
riêng từ [`notify/hbd.c`](notify/hbd.c); bản đã biên dịch `bin/hbd` được commit sẵn.

## Ghi nhận

- Hide My Applist (OSS), engine ẩn ứng dụng theo app: <https://github.com/frknkrc44/HMA-OSS>
- Tricky Store (OSS), lớp Keystore / key attestation: <https://github.com/beakthoven/TrickyStoreOSS>
  (fork từ [Tricky Store](https://github.com/5ec1cff/TrickyStore) gốc)
- NoMount, driver ẩn module kiểu mountless: <https://github.com/maxsteeel/nomount>
- Tricky Addon: Update Target List, tham khảo phần reset thuộc tính verified boot và WebUI
  danh sách mục tiêu: <https://github.com/KOWX712/Tricky-Addon-Update-Target-List>
- ReZygisk, runtime Zygisk và mẫu hook boot-completed: <https://github.com/PerformanC/ReZygisk>
- PlayIntegrityFork, nghiên cứu Play Integrity: <https://github.com/osm0sis/PlayIntegrityFork>

## Giấy phép

GNU General Public License v3.0, xem [LICENSE](LICENSE). Do có dùng các thành phần giấy
phép GPL, toàn bộ tác phẩm kết hợp được phân phối theo GPL-3.0.
