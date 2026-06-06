// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Lớp đại diện cho một kết nối người chơi (Client).
class Player {
  final WebSocket socket;
  String? roomId;
  String? symbol; // 'X' hoặc 'O'

  Player(this.socket);
}

void main() async {
  // Bản đồ quản lý các phòng chơi: roomId -> Danh sách người chơi (tối đa 2)
  final Map<String, List<Player>> rooms = {};
  
  // Lắng nghe kết nối trên tất cả các địa chỉ IPv4 tại cổng 8080
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  
  print('====================================================');
  print('   MÁY CHỦ CARO WEBSOCKET ĐANG CHẠY CHỦ ĐỘNG');
  print('   Địa chỉ: ws://localhost:8080');
  print('   Hoặc dùng IP mạng Wi-Fi để máy khác kết nối');
  print('====================================================');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      final player = Player(socket);

      socket.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            final String action = data['action'] ?? '';

            if (action == 'create') {
              // 1. Tạo mã phòng ngẫu nhiên 4 số chưa tồn tại
              final random = Random();
              String roomId;
              do {
                roomId = (1000 + random.nextInt(9000)).toString();
              } while (rooms.containsKey(roomId));

              // 2. Đăng ký phòng mới và xếp người tạo làm quân 'X'
              player.roomId = roomId;
              player.symbol = 'X';
              rooms[roomId] = [player];

              // 3. Phản hồi lại người tạo
              socket.add(jsonEncode({
                'status': 'created',
                'roomId': roomId,
                'symbol': 'X',
              }));
              print('Phòng [$roomId] được tạo bởi người chơi X.');

            } else if (action == 'join') {
              // 1. Lấy mã phòng do người chơi nhập
              final String roomId = data['roomId']?.toString() ?? '';

              if (rooms.containsKey(roomId)) {
                final roomPlayers = rooms[roomId]!;

                if (roomPlayers.length < 2) {
                  // 2. Tham gia phòng và xếp làm quân 'O'
                  player.roomId = roomId;
                  player.symbol = 'O';
                  roomPlayers.add(player);

                  // Phản hồi tham gia thành công
                  socket.add(jsonEncode({
                    'status': 'joined',
                    'roomId': roomId,
                    'symbol': 'O',
                  }));

                  // 3. Bắt đầu trận đấu: thông báo cho cả 2 người chơi
                  final startMessage = jsonEncode({
                    'status': 'start',
                    'opponentJoined': true,
                  });
                  
                  for (var p in roomPlayers) {
                    p.socket.add(startMessage);
                  }
                  
                  print('Người chơi O tham gia phòng [$roomId]. Trận đấu bắt đầu!');
                } else {
                  // Phòng đã đủ 2 người
                  socket.add(jsonEncode({
                    'status': 'error',
                    'message': 'Phòng này đã đầy người chơi!',
                  }));
                }
              } else {
                // Mã phòng không tồn tại
                socket.add(jsonEncode({
                  'status': 'error',
                  'message': 'Mã phòng không hợp lệ hoặc đã đóng!',
                }));
              }

            } else if (action == 'msg') {
              // Chuyển tiếp tin nhắn payload từ người này sang người kia trong cùng phòng
              final String? roomId = player.roomId;
              if (roomId != null && rooms.containsKey(roomId)) {
                final payload = data['payload'];
                for (var other in rooms[roomId]!) {
                  if (other != player) {
                    other.socket.add(jsonEncode({
                      'status': 'message',
                      'payload': payload,
                    }));
                  }
                }
              }
            }
          } catch (e) {
            print('Lỗi xử lý tin nhắn: $e');
          }
        },
        onDone: () {
          // Xử lý dọn dẹp khi người chơi ngắt kết nối
          final String? roomId = player.roomId;
          if (roomId != null && rooms.containsKey(roomId)) {
            rooms[roomId]!.remove(player);
            print('Một người chơi đã ngắt kết nối khỏi phòng [$roomId].');

            if (rooms[roomId]!.isEmpty) {
              rooms.remove(roomId);
              print('Phòng [$roomId] không còn người chơi nên đã được đóng.');
            } else {
              // Thông báo cho người chơi còn lại trong phòng biết đối thủ đã thoát
              rooms[roomId]!.first.socket.add(jsonEncode({
                'status': 'opponent_disconnected',
              }));
              print('Đã thông báo cho người chơi còn lại ở phòng [$roomId].');
            }
          }
        },
        onError: (error) {
          print('Lỗi kết nối Socket: $error');
        },
      );
    } else {
      // Từ chối các kết nối HTTP thông thường
      request.response
        ..statusCode = HttpStatus.forbidden
        ..write('Chỉ chấp nhận kết nối WebSocket!')
        ..close();
    }
  }
}
