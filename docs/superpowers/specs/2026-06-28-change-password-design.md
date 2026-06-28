# Thiết kế tính năng Thay đổi mật khẩu (Change Password)

Tài liệu thiết kế chi tiết cho tính năng đổi mật khẩu đặt trong màn hình Profile của ứng dụng Caro Game.

## 1. Yêu cầu hệ thống
- **Màn hình Profile mới (`ProfilePage`):** Widget màn hình mới chỉ bao gồm tính năng đổi mật khẩu.
- **Trường nhập liệu:**
  - Mật khẩu hiện tại (Current Password).
  - Mật khẩu mới (New Password) - tối thiểu 6 ký tự.
  - Xác nhận mật khẩu mới (Confirm New Password) - phải trùng khớp với mật khẩu mới.
- **Bảo mật:** Xác thực tính chính xác của mật khẩu hiện tại thông qua Supabase Auth trước khi cho phép cập nhật mật khẩu mới.
- **UI/UX:** Phong cách thiết kế đồng bộ với `LoginPage` hiện tại (Theme tối Slate-900, Card màu Slate-800, Input border, Icon ẩn/hiện mật khẩu, nút bấm màu Cyan).
- **Trạng thái sau thành công:** Đăng xuất tài khoản và tự động quay về màn hình Đăng nhập (`LoginPage`).

## 2. Thiết kế giao diện (UI)
- **Tên lớp:** `ProfilePage` (`StatefulWidget`).
- **Bố cục:**
  - Sử dụng `Scaffold` với `AppBar` tiêu đề "Trang cá nhân".
  - Một `SingleChildScrollView` chứa `Card` căn giữa màn hình với kích thước chiều rộng tối đa `420px`.
  - Các ô nhập dữ liệu sử dụng `TextFormField` với thuộc tính `obscureText` và nút `IconButton` ở hậu tố để ẩn/hiện mật khẩu.
  - Một vùng hiển thị lỗi động (`AnimatedCrossFade` hoặc `Container` lỗi) hiển thị thông báo lỗi khi có ngoại lệ từ Supabase.

## 3. Quy trình xử lý dữ liệu (Data Flow)
1. Người dùng nhấn vào Email của mình ở góc trên bên phải màn hình game.
2. `Navigator` thực hiện chuyển sang trang `ProfilePage`.
3. Người dùng điền thông tin vào form và nhấn nút "Đổi mật khẩu".
4. Biểu tượng Loading quay vòng hiển thị trên nút bấm, các ô nhập liệu tạm thời bị khóa.
5. Thực hiện xác thực mật khẩu cũ bằng cách gọi API đăng nhập thử:
   ```dart
   await Supabase.instance.client.auth.signInWithPassword(
     email: currentUserEmail,
     password: currentPassword,
   );
   ```
6. Nếu xác thực thành công, thực hiện cập nhật mật khẩu mới:
   ```dart
   await Supabase.instance.client.auth.updateUser(
     UserAttributes(password: newPassword),
   );
   ```
7. Nếu thành công, hiển thị `SnackBar` thông báo và gọi:
   ```dart
   await Supabase.instance.client.auth.signOut();
   ```
8. Chuyển hướng người dùng về màn hình đăng nhập.

## 4. Xử lý ngoại lệ (Error Handling)
- **Lỗi mật khẩu hiện tại sai:** Bắt ngoại lệ `AuthException` từ bước xác thực thử, hiển thị thông báo: *"Mật khẩu hiện tại không chính xác"*.
- **Lỗi mật khẩu mới trùng mật khẩu cũ:** (Nếu có kiểm tra từ Supabase) hiển thị thông báo tương ứng.
- **Lỗi kết nối mạng:** Hiển thị *"Không thể kết nối máy chủ. Vui lòng kiểm tra mạng và thử lại."*.

## 5. Kế hoạch kiểm thử (Testing)
- **Kiểm thử thủ công:**
  1. Nhấp vào Email ở màn hình game chính -> Xem có chuyển đến `ProfilePage` không.
  2. Bấm nút "Đổi mật khẩu" khi để trống các trường -> Xem thông báo validator có hoạt động không.
  3. Nhập mật khẩu mới ngắn hơn 6 ký tự -> Xem thông báo độ dài mật khẩu.
  4. Nhập mật khẩu xác nhận không khớp mật khẩu mới -> Xem thông báo không trùng khớp.
  5. Nhập sai mật khẩu hiện tại -> Xem hệ thống có báo lỗi mật khẩu hiện tại sai không.
  6. Nhập đúng tất cả thông tin -> Xem hệ thống có đổi mật khẩu thành công, thông báo SnackBar, đăng xuất và đẩy về màn hình LoginPage hay không.
  7. Sử dụng mật khẩu mới để đăng nhập lại -> Xem đăng nhập có thành công không.
