# Thiết kế tính năng Ghi nhận & Hiển thị Lịch sử đấu

Tài liệu thiết kế đặc tả cho hệ thống ghi nhận lịch sử đấu (Match History) trực tuyến qua Supabase và ngoại tuyến qua SharedPreferences cho Caro Game.

## 1. Yêu cầu hệ thống
- **Ghi nhận lịch sử đấu:**
  - Chế độ áp dụng: Đấu với máy (VS Bot), Đấu Online, và Chơi 2 người Local.
  - Các thông tin cần lưu:
    - Đối thủ (`opponent`): `"Bot AI (Dễ)"`, `"Bot AI (Khó)"`, email đối thủ online (ví dụ: `"opponent@gmail.com"`), hoặc `"Người chơi O"` ở chế độ local.
    - Chế độ chơi (`mode`): `"vs_bot"`, `"online"`, `"local"`.
    - Kết quả (`result`): `"win"`, `"loss"`, `"draw"`.
    - Thời gian chơi (`played_at`): Thời gian thực khi ván đấu kết thúc.
- **Màn hình chính (`CaroGamePage`):**
  - Hiển thị danh sách lịch sử đấu dưới dạng thẻ Card mới nằm trong cột bên trái (màn hình lớn) hoặc dưới cùng của trang (màn hình dọc).
  - Thẻ hiển thị danh sách cuộn được (Scrollable) chứa 10 trận đấu gần nhất.
- **Đồng bộ hóa & Dự phòng (Fallback):**
  - Đồng bộ trực tuyến với bảng `match_history` trên cơ sở dữ liệu Supabase.
  - Tự động fallback sang lưu trữ cục bộ bằng `SharedPreferences` (JSON) nếu bảng dữ liệu Supabase chưa được khởi tạo.

## 2. Thiết kế Cơ sở dữ liệu (Supabase)
Tạo bảng `public.match_history` để đồng bộ lịch sử đấu:
```sql
create table public.match_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade,
  opponent text not null,
  mode text not null,
  result text not null,
  played_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.match_history enable row level security;

-- RLS Policies
create policy "Users can view their own match history"
  on public.match_history for select
  using (auth.uid() = user_id);

create policy "Users can insert their own match history"
  on public.match_history for insert
  with check (auth.uid() = user_id);
```

## 3. Quy trình tích hợp & Dòng dữ liệu (Data Flow)

### 3.1. Lớp dữ liệu MatchRecord
```dart
class MatchRecord {
  final String opponent;
  final String mode; // 'vs_bot', 'online', 'local'
  final String result; // 'win', 'loss', 'draw'
  final DateTime playedAt;

  MatchRecord({
    required this.opponent,
    required this.mode,
    required this.result,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
    'opponent': opponent,
    'mode': mode,
    'result': result,
    'played_at': playedAt.toIso8601String(),
  };

  factory MatchRecord.fromJson(Map<String, dynamic> json) => MatchRecord(
    opponent: json['opponent'],
    mode: json['mode'],
    result: json['result'],
    playedAt: DateTime.parse(json['played_at'] ?? json['played_at']),
  );
}
```

### 3.2. Đọc Lịch sử khi Khởi chạy Game
1. Khi `CaroGamePage` tải dữ liệu ở `initState()`, thực hiện gọi hàm `_fetchMatchHistory()`.
2. Kiểm tra cờ kết nối/đồng bộ. Thử lấy dữ liệu từ bảng `match_history` của Supabase.
3. Nếu thành công, hiển thị danh sách từ DB.
4. Nếu thất bại (catch lỗi), tự động tải danh sách từ `SharedPreferences` cục bộ qua key `'local_match_history'`.

### 3.3. Ghi nhận Lịch sử khi Kết thúc trận đấu
1. Khi ván đấu kết thúc (Win/Loss/Draw/Timeout/Surrender):
   - Chế độ Local:
     - Winner O -> O thắng, X thua.
     - Winner X -> X thắng, O thua.
   - Chế độ VS Bot:
     - Player X thắng -> `win`.
     - Bot O thắng -> `loss`.
   - Chế độ Online:
     - Winner == mySymbol -> `win`.
     - Winner != mySymbol -> `loss`.
2. Tạo đối tượng `MatchRecord` mới.
3. Gọi hàm `_saveMatchRecord(MatchRecord record)`.
4. Nếu kết nối database hoạt động, insert dòng mới vào Supabase:
   - `user_id`: ID user hiện tại.
   - `opponent`, `mode`, `result`, `played_at`.
5. Nếu insert lỗi hoặc không có bảng:
   - Lưu record mới vào danh sách `SharedPreferences` nội bộ.
6. Cập nhật danh sách state hiển thị trên màn hình chính ngay lập tức để người chơi nhìn thấy.

## 4. Giao diện người dùng (UI Specs)
Card lịch sử đấu sử dụng theme tối đồng bộ (`Color(0xFF1E293B)`):
- Tiêu đề: **Lịch sử đấu** kèm icon `Icons.history`.
- Mỗi dòng trận đấu là một `Row`:
  - Biểu tượng chế độ: `🤖`, `🌐`, `👥`
  - Tên đối thủ nổi bật màu xám/trắng nhạt: `"Đấu với: Bot AI (Khó)"`
  - Thời gian hiển thị nhỏ bên phải: `"28/06 22:50"`
  - Nhãn kết quả bo góc:
    - `"Thắng"`: nền xanh Cyan mờ, chữ xanh Cyan.
    - `"Thua"`: nền đỏ Rose mờ, chữ đỏ Rose.
    - `"Hòa"`: nền xám Slate mờ, chữ xám Slate.
