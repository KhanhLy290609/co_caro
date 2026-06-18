# Hướng dẫn & Nhật ký Deploy lên GitHub Pages

Tài liệu này ghi chép lại các thiết lập deploy tự động cho dự án game Caro lên GitHub Pages thông qua GitHub Actions.

## Các file đã tạo / chỉnh sửa

1. **`lib/main.dart`** (Chỉnh sửa):
   - Thêm tính năng đăng ký tài khoản qua Supabase Auth.
   - Ép buộc đăng nhập lại sau khi đăng ký thành công (gọi `signOut`).
   - Bổ sung xác nhận trước khi đăng xuất.
   - Thêm hiệu ứng phóng to quân cờ mới trong 200ms và highlight nhấp nháy màu xanh/đỏ theo người thắng cuộc.
   - Tích hợp hệ thống pháo hoa hạt (particle system) kéo dài 5 giây khi có người thắng.
2. **`test/widget_test.dart`** (Chỉnh sửa):
   - Cập nhật smoke test khớp với giao diện tiếng Việt có dấu.
3. **`.github/workflows/deploy.yml`** (Tạo mới):
   - Workflow tự động chạy khi push lên nhánh `Sweet`. Tự động cài đặt Flutter, build web (`--base-href "/co_caro/"`) và deploy trực tiếp lên GitHub Pages.
4. **`DEPLOYS.md`** (Tạo mới):
   - File này (Tài liệu hướng dẫn deploy).

## Các lệnh Git & GitHub đã sử dụng

Các lệnh sau được chạy để đồng bộ hóa và kích hoạt deploy:
- `git add .` (Đưa toàn bộ thay đổi vào hàng đợi)
- `git commit -m "feat: add registration, animations, and pages deploy workflow"` (Commit cục bộ)
- `git push origin Sweet` (Push code lên nhánh Sweet trên GitHub)
- `gh run list` (Theo dõi tiến trình chạy workflow từ dòng lệnh)

## Link chạy online (GitHub Pages)

Sau khi quá trình build kết thúc thành công, game sẽ chạy tại:
👉 **[https://KhanhLy290609.github.io/co_caro/](https://KhanhLy290609.github.io/co_caro/)**

---

## Các lưu ý & Thao tác thủ công cần thiết

### 1. Kích hoạt nguồn GitHub Actions cho Pages (Quan trọng)
Mặc dù workflow đã được đẩy lên, bạn cần cấu hình repo GitHub cho phép deploy từ Actions:
1. Truy cập repo của bạn trên trình duyệt: `https://github.com/KhanhLy290609/co_caro`.
2. Vào tab **Settings** (Cài đặt) -> chọn mục **Pages** ở thanh bên trái.
3. Tại phần **Build and deployment** -> **Source**, chọn **GitHub Actions** (thay vì *Deploy from a branch*).
4. Nhờ thiết lập này, GitHub sẽ tự động lấy kết quả từ workflow để đưa lên trang web online mỗi khi bạn push code.

### 2. Vấn đề Repo Private
Vì repo hiện tại là **Private**, tính năng GitHub Pages chỉ khả dụng miễn phí nếu repo là **Public** (hoặc bạn phải đăng ký tài khoản GitHub Pro/Enterprise).
Nếu bạn muốn deploy miễn phí, hãy chuyển repo sang chế độ Public bằng lệnh sau hoặc chỉnh trong Settings:
```powershell
gh repo edit --visibility public
```

### 3. Cấu hình Supabase Redirect URL
Do bạn chuyển từ chạy cục bộ (`localhost`) lên chạy online (`github.io`), nếu bạn bật tính năng "Confirm Email" trong Supabase:
- Hãy truy cập **Supabase Dashboard** -> **Authentication** -> **URL Configuration**.
- Thêm link `https://KhanhLy290609.github.io/co_caro/` vào mục **Redirect URLs** hoặc đặt làm **Site URL** để email xác nhận trỏ về đúng trang web game online sau khi người dùng click xác thực.
