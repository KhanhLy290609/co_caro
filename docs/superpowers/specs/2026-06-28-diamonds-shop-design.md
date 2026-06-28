# Thiết kế tính năng Tích lũy Kim cương & Cửa hàng Icon

Tài liệu thiết kế đặc tả cho hệ thống kim cương, mua sắm và thay đổi icon quân cờ của người chơi trong Caro Game.

## 1. Yêu cầu hệ thống
- **Tích lũy kim cương:**
  - Chế độ áp dụng: Đấu với máy (VS Bot) và Đấu Online.
  - Thắng: +10 kim cương.
  - Thua/Hết giờ lượt đi: -5 kim cương (giới hạn tối thiểu là 0, không cho phép số dư âm).
- **Màn hình chính (`CaroGamePage`):**
  - Hiển thị số kim cương hiện tại của tài khoản ngay bên dưới trạng thái lượt chơi.
- **Màn hình Profile (`ProfilePage`):**
  - Hiển thị số dư kim cương hiện tại.
  - Hiển thị danh sách quân cờ đã sở hữu và cho phép chọn quân cờ active.
  - Hiển thị cửa hàng mua sắm icon quân cờ bằng kim cương.
  - Giữ nguyên tính năng đổi mật khẩu ở phần dưới cùng của trang.
- **Danh sách Icon bán trong Shop:**
  - Mệnh giá 5 💎: ⭐, 🔥, 💧
  - Mệnh giá 20 💎: 👑, ⚡, 🍀
  - Mệnh giá 50 💎: 💎, 🚀, 👾
  - Mệnh giá 100 💎: 🎯, 🐉, 🦄
- **Đồng bộ hóa:** Đồng bộ trực tuyến số kim cương, danh sách icon đã mua và icon đang chọn thông qua bảng `profiles` trong Supabase Database.

## 2. Thiết kế Cơ sở dữ liệu (Supabase)
Tạo bảng `public.profiles` chứa dữ liệu người dùng:
```sql
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  diamonds integer not null default 0,
  unlocked_icons text[] not null default array['X', 'O'],
  selected_icon text not null default 'X',
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.profiles enable row level security;

-- RLS Policies
create policy "Users can view their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);
```

## 3. Quy trình tích hợp & Dòng dữ liệu (Data Flow)

### 3.1. Khởi tạo Profile khi Đăng nhập
Khi người dùng đăng nhập thành công và vào game (`AuthGate` chuyển sang `CaroGamePage`):
1. Gọi API select dòng profile của user hiện tại.
2. Nếu chưa có, thực hiện insert dòng mặc định:
   - `diamonds`: 0
   - `unlocked_icons`: `['X', 'O']`
   - `selected_icon`: `X`

### 3.2. Thay đổi Quân cờ khi Chơi Game
- Thay vì sử dụng mặc định quân cờ X và O cứng, quân cờ của người chơi chính (Player X hoặc Player O tùy thuộc vào lượt hoặc chế độ chơi) sẽ được lấy từ `profiles.selected_icon`.
- **VS Bot:** Người chơi sử dụng icon đã chọn (mặc định X), máy sử dụng O (hoặc một icon ngẫu nhiên/cố định khác).
- **Online:** Quân cờ của thiết bị này (`mySymbol`) sẽ sử dụng icon đã chọn của user.

### 3.3. Nhận thưởng/Khấu trừ Kim cương
Khi game kết thúc:
1. Tính toán số kim cương mới (`current + 10` nếu thắng, `max(0, current - 5)` nếu thua).
2. Gọi Supabase update bảng `profiles` đặt `diamonds = newDiamonds` cho ID người dùng.
3. Cập nhật trạng thái state trên màn hình để hiển thị số kim cương mới ngay lập tức.

### 3.4. Mua hàng trong Shop
Trong `ProfilePage`:
1. Người dùng bấm mua một icon trong Shop Grid.
2. Kiểm tra điều kiện: `diamonds >= price`. Nếu không đủ, hiển thị thông báo lỗi.
3. Nếu đủ, thực hiện update cơ sở dữ liệu:
   - Trừ số kim cương tương ứng.
   - Thêm icon mới vào danh sách `unlocked_icons`.
4. Sau khi cập nhật DB thành công, gọi `setState` để vẽ lại giao diện (Nút "Mua" chuyển thành "Đã sở hữu", số kim cương số dư giảm).

## 4. Kế hoạch kiểm thử (Testing)
- **Kiểm thử tự động:**
  - Viết widget test kiểm thử giao diện Shop hiển thị đúng danh sách vật phẩm.
  - Viết unit test giả lập tài khoản mua hàng thành công và thất bại do thiếu tiền.
- **Kiểm thử thủ công:**
  1. Đăng nhập tài khoản -> Kiểm tra số kim cương hiển thị mặc định là 0 💎.
  2. Đấu với máy thắng -> Xem kim cương có tăng lên thành 10 💎 không.
  3. Vào trang Profile -> Mua icon Ngôi sao ⭐ giá 5 💎 -> Kiểm tra kim cương giảm còn 5 💎, nút Mua biến thành Đã sở hữu.
  4. Chọn quân cờ đang dùng là ⭐.
  5. Ra ngoài chơi game -> Xem quân cờ của mình trên bàn cờ có đổi thành ⭐ hay không.
