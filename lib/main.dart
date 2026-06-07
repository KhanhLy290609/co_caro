// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'dart:async';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://caddicxvszitasqahdck.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhZGRpY3h2c3ppdGFzcWFoZGNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MTcwMjYsImV4cCI6MjA5NjI5MzAyNn0.GmPJHIrFkFtruwmqsQioDN2atv1VApV68y_qG1dd4TA',
  );
  runApp(const MyApp());
}

/// Widget gốc của ứng dụng. Cấu hình theme tối (Dark Mode) hiện đại.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caro Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(
          0xFF0F172A,
        ), // Màu nền Slate-900 sang trọng
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4), // Màu Xanh Cyan của quân X
          secondary: Color(0xFFF43F5E), // Màu Đỏ Rose của quân O
          surface: Color(0xFF1E293B), // Màu nền thẻ Slate-800
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Lớp đại diện cho một nước đi, dùng để lưu lịch sử phục vụ chức năng đi lại (Undo).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _session = _supabase.auth.currentSession;
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _session = data.session;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const LoginPage();
    }

    return const CaroGamePage();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Khong the dang nhap. Vui long thu lai.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: const Color(0xFF1E293B),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.grid_on_rounded,
                          size: 44,
                          color: Color(0xFF06B6D4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dang nhap',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Su dung email va mat khau Supabase de vao game.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Vui long nhap email';
                            }
                            if (!email.contains('@')) {
                              return 'Email khong hop le';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Mat khau',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Hien mat khau'
                                  : 'An mat khau',
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Vui long nhap mat khau';
                            }
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0x33EF4444),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFFCA5A5)),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _login,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            _isLoading ? 'Dang dang nhap...' : 'Dang nhap',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Move {
  final int row;
  final int col;
  final String symbol; // 'X' hoặc 'O'

  Move({required this.row, required this.col, required this.symbol});
}

/// Trang chơi game chính.
class CaroGamePage extends StatefulWidget {
  const CaroGamePage({super.key});

  @override
  State<CaroGamePage> createState() => _CaroGamePageState();
}

class _CaroGamePageState extends State<CaroGamePage> {
  // --- Các biến trạng thái Game cơ bản ---
  int boardSize = 20; // Kích thước bàn cờ động (mặc định là 20x20)
  int winCondition = 5; // Số quân liên tiếp cần để thắng (mặc định là 5)
  late List<List<String>> board; // Ma trận cờ
  late bool isXTurn; // Trạng thái lượt đi (X đi trước)
  late bool gameOver; // Trạng thái kết thúc ván
  List<List<int>> winningCells = []; // Các ô thắng cuộc
  List<int>? lastMove; // Ô đi gần nhất
  List<Move> history = []; // Lịch sử đi cờ

  // Bộ đếm điểm số
  int xWins = 0;
  int oWins = 0;
  int draws = 0;

  // Tùy chọn kích thước bàn cờ
  final List<Map<String, dynamic>> boardSizeOptions = [
    {'label': '3x3 (Cần 3)', 'size': 3, 'win': 3},
    {'label': '5x5 (Cần 5)', 'size': 5, 'win': 5},
    {'label': '10x10 (Cần 5)', 'size': 10, 'win': 5},
    {'label': '20x20 (Cần 5)', 'size': 20, 'win': 5},
  ];

  // --- Các biến phục vụ chế độ kết nối Online qua Supabase ---
  bool isOnlineMode = false; // Có đang chơi Online không
  bool isConnected = false; // Đã kết nối thành công tới phòng chưa
  bool isConnecting = false; // Đang trong quá trình kết nối tới máy chủ
  String? connectionError; // Thông báo lỗi kết nối nếu có
  String? currentRoomId; // ID thực tế của phòng trong DB (UUID)
  String? currentRoomCode; // Mã phòng chơi hiện tại (4 chữ số) hiển thị cho user
  String? mySymbol; // Ký tự quân cờ của thiết bị này ('X' hoặc 'O')
  bool isOpponentJoined = false; // Đối thủ đã tham gia phòng chưa

  final SupabaseClient supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _roomSubscription;
  RealtimeChannel? _presenceChannel;
  late String myPlayerId; // Client ID duy nhất để phân biệt người chơi

  // Controllers cho các ô nhập liệu
  final TextEditingController _roomIdController = TextEditingController();

  // --- Các biến phục vụ Đồng hồ đếm ngược & Gợi ý nước đi ---
  int selectedTimerDuration = 30; // 0: Không giới hạn, 15s, 30s
  int remainingTime = 30; // Thời gian còn lại của lượt đi hiện tại
  Timer? _turnTimer; // Đối tượng Timer đếm ngược
  List<int>?
  suggestedCell; // Tọa độ [row, col] được gợi ý bởi AI (nhấp nháy màu xanh)

  @override
  void initState() {
    super.initState();
    myPlayerId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    _initGameData();
    _startTimer(); // Khởi chạy timer ban đầu cho X đi trước
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _cancelTimer();
    unawaited(_disconnect(updateState: false));
    super.dispose();
  }

  /// Khởi tạo dữ liệu bàn cờ sạch
  void _initGameData() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    isXTurn = true;
    gameOver = false;
    winningCells = [];
    lastMove = null;
    history = [];
    suggestedCell = null;
  }

  // --- LOGIC HỖ TRỢ ĐỒNG HỒ ĐẾM NGƯỢC (TIMER) ---

  /// Bắt đầu đếm ngược thời gian
  void _startTimer() {
    _cancelTimer();
    if (selectedTimerDuration == 0 || gameOver) return;

    // Chỉ đếm ngược khi ván đấu thực sự bắt đầu:
    // - Local: Đã có ít nhất một nước đi trên bàn cờ (history không trống).
    // - Online: Khi đối thủ đã tham gia phòng chơi.
    final bool hasStarted = isOnlineMode ? isOpponentJoined : history.isNotEmpty;
    if (!hasStarted) {
      setState(() {
        remainingTime = selectedTimerDuration;
      });
      return;
    }

    setState(() {
      remainingTime = selectedTimerDuration;
    });

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          _handleTimeout();
        }
      });
    });
  }

  /// Hủy bỏ đếm ngược
  void _cancelTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  /// Xử lý sự kiện khi hết giờ lượt đi
  void _handleTimeout() {
    _cancelTimer();
    setState(() {
      gameOver = true;
      final String losingSymbol = isXTurn ? 'X' : 'O';
      final String winningSymbol = isXTurn ? 'O' : 'X';

      if (winningSymbol == 'X') {
        xWins++;
      } else {
        oWins++;
      }

      if (isOnlineMode) {
        final bool isMyTurn =
            (isXTurn && mySymbol == 'X') || (!isXTurn && mySymbol == 'O');
        if (isMyTurn) {
          // Cập nhật database báo hết giờ
          supabase.from('rooms').update({
            'game_over': true,
            'status': 'ended',
            'x_wins': winningSymbol == 'X' ? xWins + 1 : xWins,
            'o_wins': winningSymbol == 'O' ? oWins + 1 : oWins,
            'last_action': 'timeout',
          }).eq('id', currentRoomId!);
          
          _showEndGameDialog(
            'Hết Giờ! ⏰',
            'Bạn đã hết thời gian suy nghĩ ván cờ và bị xử thua ván này!',
            winningSymbol,
          );
        }
      } else {
        _showEndGameDialog(
          'Hết Giờ! ⏰',
          'Người chơi $losingSymbol đã hết thời gian suy nghĩ và bị xử thua!',
          winningSymbol,
        );
      }
    });
  }

  // --- HÀM ĐỒNG BỘ VÀ XỬ LÝ SUPABASE ---

  /// Tạo hoặc Tham gia phòng chơi trên Supabase
  void _connectSupabase(bool isCreate, {String? joinRoomCode}) async {
    if (isConnecting) return;

    setState(() {
      isConnecting = true;
      connectionError = null;
    });

    try {
      if (isCreate) {
        // --- TẠO PHÒNG MỚI ---
        String code = '';
        bool isUnique = false;
        int attempts = 0;
        
        while (!isUnique && attempts < 10) {
          attempts++;
          code = (1000 + Random().nextInt(9000)).toString(); // 1000 to 9999
          final existing = await supabase
              .from('rooms')
              .select('id')
              .eq('room_code', code)
              .inFilter('status', ['waiting', 'playing'])
              .maybeSingle();
              
          if (existing == null) {
            isUnique = true;
          }
        }

        if (!isUnique) {
          throw Exception('Không thể tạo mã phòng độc nhất. Vui lòng thử lại!');
        }

        final roomData = await supabase.from('rooms').insert({
          'room_code': code,
          'player_x': myPlayerId,
          'status': 'waiting',
          'board_size': boardSize,
          'win_condition': winCondition,
          'timer_duration': selectedTimerDuration,
          'is_x_turn': true,
          'game_over': false,
          'history': [],
          'winning_cells': [],
          'x_wins': xWins,
          'o_wins': oWins,
          'draws': draws,
        }).select().single();

        final String roomId = roomData['id'];

        setState(() {
          isConnected = true;
          isConnecting = false;
          currentRoomId = roomId;
          currentRoomCode = code;
          mySymbol = 'X';
          isOpponentJoined = false;
        });

        _subscribeToRoom(roomId);
        _setupPresence(roomId);
      } else {
        // --- THAM GIA PHÒNG ---
        if (joinRoomCode == null || joinRoomCode.length != 4) {
          throw Exception('Mã phòng phải có đúng 4 chữ số!');
        }

        final roomData = await supabase
            .from('rooms')
            .select()
            .eq('room_code', joinRoomCode)
            .eq('status', 'waiting')
            .maybeSingle();

        if (roomData == null) {
          throw Exception('Phòng không tồn tại hoặc đã đầy/bắt đầu!');
        }

        final String roomId = roomData['id'];

        final updatedRoom = await supabase
            .from('rooms')
            .update({
              'player_o': myPlayerId,
              'status': 'playing',
              'last_action': 'join',
            })
            .eq('id', roomId)
            .select()
            .single();

        setState(() {
          isConnected = true;
          isConnecting = false;
          currentRoomId = roomId;
          currentRoomCode = joinRoomCode;
          mySymbol = 'O';
          isOpponentJoined = true;
          
          boardSize = updatedRoom['board_size'];
          winCondition = updatedRoom['win_condition'];
          selectedTimerDuration = updatedRoom['timer_duration'];
          _initGameData();
        });

        _subscribeToRoom(roomId);
        _setupPresence(roomId);
        _startTimer();
      }
    } catch (e) {
      setState(() {
        isConnecting = false;
        connectionError = e is PostgrestException ? e.message : e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _subscribeToRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty && mounted) {
            _handleRoomUpdate(data.first);
          }
        });
  }

  void _handleRoomUpdate(Map<String, dynamic> room) {
    final String lastAction = room['last_action'] ?? '';
    
    if (mySymbol == 'X' && room['player_o'] != null && !isOpponentJoined) {
      setState(() {
        isOpponentJoined = true;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đối thủ đã tham gia phòng. Trận đấu bắt đầu!')),
      );
    }

    final List<dynamic> historyData = room['history'] ?? [];
    final bool dbIsXTurn = room['is_x_turn'] ?? true;
    final bool dbGameOver = room['game_over'] ?? false;
    final List<dynamic> winningCellsData = room['winning_cells'] ?? [];
    final Map<String, dynamic>? lastMoveData = room['last_move'];
    
    final int dbXWins = room['x_wins'] ?? 0;
    final int dbOWins = room['o_wins'] ?? 0;
    final int dbDraws = room['draws'] ?? 0;
    
    final int dbBoardSize = room['board_size'] ?? boardSize;
    final int dbWinCondition = room['win_condition'] ?? winCondition;
    final int dbTimerDuration = room['timer_duration'] ?? selectedTimerDuration;

    final bool previousGameOver = gameOver;

    setState(() {
      if (boardSize != dbBoardSize || winCondition != dbWinCondition) {
        boardSize = dbBoardSize;
        winCondition = dbWinCondition;
      }
      
      selectedTimerDuration = dbTimerDuration;
      xWins = dbXWins;
      oWins = dbOWins;
      draws = dbDraws;
      
      board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
      history = [];
      for (final move in historyData) {
        final int r = move['row'];
        final int c = move['col'];
        final String sym = move['symbol'];
        board[r][c] = sym;
        history.add(Move(row: r, col: c, symbol: sym));
      }
      
      isXTurn = dbIsXTurn;
      gameOver = dbGameOver;
      
      if (lastMoveData != null) {
        lastMove = [lastMoveData['row'], lastMoveData['col']];
      } else {
        lastMove = null;
      }
      
      winningCells = [];
      for (final cell in winningCellsData) {
        winningCells.add([cell[0], cell[1]]);
      }
    });
    
    if (!previousGameOver && gameOver) {
      String title = '';
      String message = '';
      String winnerSymbol = '';
      
      if (lastAction == 'timeout') {
        final String losingSymbol = isXTurn ? 'X' : 'O';
        winnerSymbol = losingSymbol == 'X' ? 'O' : 'X';
        title = 'Chiến Thắng! ⏰';
        message = 'Đối thủ đã hết thời gian suy nghĩ. Bạn giành chiến thắng!';
      } else if (winningCells.isNotEmpty && lastMove != null) {
        winnerSymbol = board[lastMove![0]][lastMove![1]];
        if (winnerSymbol == mySymbol) {
          title = 'Chiến Thắng! 🎉';
          message = 'Chúc mừng bạn đã giành chiến thắng ván cờ này!';
        } else {
          title = 'Thất Bại! 😢';
          message = 'Đối thủ ($winnerSymbol) đã giành chiến thắng ván này!';
        }
      } else {
        title = 'Hòa Cờ! 🤝';
        message = 'Tất cả các ô trên bàn cờ đã đầy!';
      }
      
      _showEndGameDialog(title, message, winnerSymbol);
    }

    if (!gameOver && isOpponentJoined) {
      _startTimer();
    } else {
      _cancelTimer();
    }
  }

  void _setupPresence(String roomId) {
    _presenceChannel = supabase.channel('presence_$roomId');
    
    _presenceChannel!.onPresenceSync((payload) {
      if (!mounted) return;
      final state = _presenceChannel!.presenceState();
      
      final List<String> presentPlayers = [];
      for (final presenceState in state) {
        for (final presence in presenceState.presences) {
          final String? id = presence.payload['player_id'];
          if (id != null) {
            presentPlayers.add(id);
          }
        }
      }
      
      final bool opponentStillHere = presentPlayers.any((id) => id != myPlayerId);
      
      if (isOpponentJoined && !opponentStillHere) {
        _cancelTimer();
        setState(() {
          isOpponentJoined = false;
        });
        _showOpponentDisconnectedDialog();
      }
    }).subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed && mounted) {
        await _presenceChannel!.track({
          'player_id': myPlayerId,
        });
      }
    });
  }

  Future<void> _disconnect({String? error, bool updateState = true}) async {
    _cancelTimer();
    _roomSubscription?.cancel();
    _roomSubscription = null;
    
    if (_presenceChannel != null) {
      await _presenceChannel!.unsubscribe();
      _presenceChannel = null;
    }
    
    if (currentRoomId != null) {
      try {
        await supabase.from('rooms').update({
          'status': 'ended',
        }).eq('id', currentRoomId!);
      } catch (e) {
        // Ignored
      }
    }

    if (!updateState || !mounted) return;

    setState(() {
      isConnected = false;
      isConnecting = false;
      currentRoomId = null;
      currentRoomCode = null;
      mySymbol = null;
      isOpponentJoined = false;
      if (error != null) {
        connectionError = error;
      }
    });
  }

  Future<void> _logout() async {
    await _disconnect(updateState: false);
    await Supabase.instance.client.auth.signOut();
  }

  void _executeLocalUndo() {
    if (history.isEmpty || gameOver) return;
    setState(() {
      final last = history.removeLast();
      board[last.row][last.col] = '';
      isXTurn = !isXTurn;
      if (history.isNotEmpty) {
        lastMove = [history.last.row, history.last.col];
      } else {
        lastMove = null;
      }
      winningCells = [];
      suggestedCell = null;
    });
  }

  void _executeLocalResetBoard() {
    setState(() {
      _initGameData();
    });
  }

  void _executeLocalResetAll() {
    _executeLocalResetBoard();
    setState(() {
      xWins = 0;
      oWins = 0;
      draws = 0;
    });
  }

  void _executeLocalChangeSize(int size, int win) {
    setState(() {
      boardSize = size;
      winCondition = win;
      _initGameData();
    });
  }

  void _executeLocalTimerChange(int duration) {
    setState(() {
      selectedTimerDuration = duration;
    });
    _startTimer();
  }

  // --- HÀM TƯƠNG TÁC TỪ WIDGETS ---

  /// Rút nước đi
  void undo() async {
    if (isOnlineMode) {
      if (history.isEmpty || gameOver || !isOpponentJoined) return;
      
      final List<dynamic> newHistory = history.map((m) => {
        'row': m.row,
        'col': m.col,
        'symbol': m.symbol,
      }).toList()..removeLast();

      Map<String, dynamic>? newLastMove;
      if (newHistory.isNotEmpty) {
        final last = newHistory.last;
        newLastMove = {'row': last['row'], 'col': last['col']};
      }

      await supabase.from('rooms').update({
        'history': newHistory,
        'is_x_turn': !isXTurn,
        'last_move': newLastMove,
        'last_action': 'undo',
      }).eq('id', currentRoomId!);
    } else {
      _executeLocalUndo();
      _startTimer();
    }
  }

  /// Chơi ván mới
  void resetBoard() async {
    if (isOnlineMode) {
      if (!isOpponentJoined) return;
      await supabase.from('rooms').update({
        'history': [],
        'is_x_turn': true,
        'game_over': false,
        'winning_cells': [],
        'last_move': null,
        'last_action': 'reset',
      }).eq('id', currentRoomId!);
    } else {
      _executeLocalResetBoard();
      _startTimer();
    }
  }

  /// Reset tỉ số
  void resetAll() async {
    if (isOnlineMode) {
      if (!isOpponentJoined) return;
      await supabase.from('rooms').update({
        'history': [],
        'is_x_turn': true,
        'game_over': false,
        'winning_cells': [],
        'last_move': null,
        'x_wins': 0,
        'o_wins': 0,
        'draws': 0,
        'last_action': 'reset_all',
      }).eq('id', currentRoomId!);
    } else {
      _executeLocalResetAll();
      _startTimer();
    }
  }

  /// Thay đổi kích cỡ
  void handleChangeSize(int size, int win) async {
    if (isOnlineMode) {
      if (!isOpponentJoined) return;
      await supabase.from('rooms').update({
        'board_size': size,
        'win_condition': win,
        'history': [],
        'is_x_turn': true,
        'game_over': false,
        'winning_cells': [],
        'last_move': null,
        'last_action': 'change_size',
      }).eq('id', currentRoomId!);
    } else {
      _executeLocalChangeSize(size, win);
      _startTimer();
    }
  }

  /// Đổi cấu hình đồng hồ
  void handleTimerChange(int duration) async {
    if (isOnlineMode) {
      if (!isOpponentJoined) return;
      await supabase.from('rooms').update({
        'timer_duration': duration,
        'last_action': 'change_timer',
      }).eq('id', currentRoomId!);
    } else {
      _executeLocalTimerChange(duration);
    }
  }

  // --- THUẬT TOÁN HINT GỢI Ý NƯỚC ĐI (HEURISTIC AI) ---

  /// Kích hoạt gợi ý nước đi tốt nhất cho người chơi hiện tại
  void suggestMove() {
    if (gameOver) return;
    if (isOnlineMode) {
      if (!isOpponentJoined) return;
      // Chỉ gợi ý nếu đang đến lượt mình đi cờ
      final bool isMyTurn =
          (isXTurn && mySymbol == 'X') || (!isXTurn && mySymbol == 'O');
      if (!isMyTurn) return;
    }

    final bestMove = _getAIMoveSuggestion();
    if (bestMove != null) {
      setState(() {
        suggestedCell = bestMove;
      });
      // Tự động tắt nhấp nháy gợi ý sau 3 giây
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            suggestedCell = null;
          });
        }
      });
    }
  }

  /// Thuật toán tìm nước đi tốt nhất
  List<int>? _getAIMoveSuggestion() {
    int bestScore = -1;
    List<int>? bestMove;
    final String mySym = isXTurn ? 'X' : 'O';
    final String oppSym = isXTurn ? 'O' : 'X';

    // Tạo danh sách các ứng viên ô trống (chỉ quét các ô có lân cận cờ trong bán kính 2 ô để tối ưu tốc độ)
    List<List<int>> candidateCells = [];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c].isEmpty) {
          if (_hasNeighbor(r, c)) {
            candidateCells.add([r, c]);
          }
        }
      }
    }

    // Nếu bàn cờ trống hoàn toàn, gợi ý ô ở giữa
    if (candidateCells.isEmpty) {
      return [boardSize ~/ 2, boardSize ~/ 2];
    }

    for (final cell in candidateCells) {
      final int r = cell[0];
      final int c = cell[1];

      // Đánh giá điểm nếu mình đi cờ vào đây (Tấn công)
      final int attackScore = _evaluateCellForSymbol(r, c, mySym);
      // Đánh giá điểm nếu đối thủ đi cờ vào đây (Phòng thủ)
      final int defenseScore = _evaluateCellForSymbol(r, c, oppSym);

      // Điểm tổng hợp bằng Tấn công + Phòng thủ (Ưu tiên cản phá hoặc tự thắng)
      final int totalScore = attackScore + defenseScore;

      if (totalScore > bestScore) {
        bestScore = totalScore;
        bestMove = [r, c];
      }
    }

    return bestMove;
  }

  /// Kiểm tra xem ô cờ có quân cờ lân cận trong bán kính 2 ô hay không
  bool _hasNeighbor(int row, int col) {
    for (int dr = -2; dr <= 2; dr++) {
      for (int dc = -2; dc <= 2; dc++) {
        if (dr == 0 && dc == 0) continue;
        int r = row + dr;
        int c = col + dc;
        if (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
          if (board[r][c].isNotEmpty) return true;
        }
      }
    }
    return false;
  }

  /// Chấm điểm ô cờ cho một ký hiệu nhất định
  int _evaluateCellForSymbol(int row, int col, String symbol) {
    final directions = [
      [0, 1], // Ngang
      [1, 0], // Dọc
      [1, 1], // Chéo \
      [1, -1], // Chéo /
    ];

    int totalScore = 0;

    for (final dir in directions) {
      int dRow = dir[0];
      int dCol = dir[1];

      int count = 1; // Ô cờ đang chấm điểm
      int openEnds = 0; // Đếm số đầu mở thoáng

      // Kiểm tra hướng tiến
      int r = row + dRow;
      int c = col + dCol;
      while (r >= 0 &&
          r < boardSize &&
          c >= 0 &&
          c < boardSize &&
          board[r][c] == symbol) {
        count++;
        r += dRow;
        c += dCol;
      }
      if (r >= 0 &&
          r < boardSize &&
          c >= 0 &&
          c < boardSize &&
          board[r][c].isEmpty) {
        openEnds++;
      }

      // Kiểm tra hướng lùi
      r = row - dRow;
      c = col - dCol;
      while (r >= 0 &&
          r < boardSize &&
          c >= 0 &&
          c < boardSize &&
          board[r][c] == symbol) {
        count++;
        r -= dRow;
        c -= dCol;
      }
      if (r >= 0 &&
          r < boardSize &&
          c >= 0 &&
          c < boardSize &&
          board[r][c].isEmpty) {
        openEnds++;
      }

      // Cấp trọng số điểm cho các cụm cờ
      if (count >= winCondition) {
        totalScore += 1000000; // Có thể thắng ngay lập tức
      } else if (count == 4) {
        if (openEnds == 2) {
          totalScore += 150000; // 4 quân hai đầu mở (cực kỳ nguy hiểm)
        } else if (openEnds == 1) {
          totalScore += 20000; // 4 quân bị chặn 1 đầu
        }
      } else if (count == 3) {
        if (openEnds == 2) {
          totalScore += 10000; // 3 quân thoáng 2 đầu
        } else if (openEnds == 1) {
          totalScore += 2000; // 3 quân chặn 1 đầu
        }
      } else if (count == 2) {
        if (openEnds == 2) {
          totalScore += 1000;
        } else if (openEnds == 1) {
          totalScore += 200;
        }
      } else if (count == 1) {
        if (openEnds == 2) {
          totalScore += 20;
        }
      }
    }

    return totalScore;
  }

  // --- HÀM TƯƠNG TÁC TỪ WIDGETS ---

  Widget _buildCaroBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        double boardDisplaySize =
            (availableWidth < availableHeight
                ? availableWidth
                : availableHeight) -
            16.0;

        if (boardDisplaySize < 180) {
          boardDisplaySize = 180;
        }

        if (boardSize <= 5) {
          final double maxSize = boardSize * 80.0;
          if (boardDisplaySize > maxSize) {
            boardDisplaySize = maxSize;
          }
        }

        final double cellWidth = boardDisplaySize / boardSize;

        return Center(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.5,
            child: Container(
              width: boardDisplaySize,
              height: boardDisplaySize,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                border: Border.all(color: const Color(0xFF334155), width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: boardSize,
                ),
                itemCount: boardSize * boardSize,
                itemBuilder: (context, index) {
                  final row = index ~/ boardSize;
                  final col = index % boardSize;
                  final symbol = board[row][col];

                  final isWinning = winningCells.any(
                    (cell) => cell[0] == row && cell[1] == col,
                  );
                  final isLastMove =
                      lastMove != null &&
                      lastMove![0] == row &&
                      lastMove![1] == col;
                  final isSuggested =
                      suggestedCell != null &&
                      suggestedCell![0] == row &&
                      suggestedCell![1] == col;

                  return BoardCell(
                    row: row,
                    col: col,
                    symbol: symbol,
                    isWinning: isWinning,
                    isLastMove: isLastMove,
                    isSuggested: isSuggested,
                    activePlayerSymbol: isXTurn ? 'X' : 'O',
                    cellWidth: cellWidth,
                    onTap: () => _handleCellTap(row, col),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- HÀM BUILD LAYOUTS ---

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 950;
    final String? userEmail = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

              Expanded(
                child: isOnlineMode && !isConnected
                    ? _buildConnectionScreen()
                    : (isLargeScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildTurnIndicator(),
                                        const SizedBox(height: 16),
                                        _buildConfigCard(),
                                        const SizedBox(height: 16),
                                        _buildScoreboard(),
                                        const SizedBox(height: 16),
                                        _buildControlPanel(),
                                        const SizedBox(height: 16),
                                        _buildRulesCard(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Card(
                                    elevation: 4,
                                    color: const Color(0xFF0F172A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(
                                        color: Color(0xFF1E293B),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Expanded(child: _buildCaroBoard()),
                                          const SizedBox(height: 8),
                                          _buildBoardInstructions(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildTurnIndicator(),
                                const SizedBox(height: 12),
                                _buildConfigCard(),
                                const SizedBox(height: 12),
                                _buildScoreboardCompact(),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF1E293B),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(child: _buildCaroBoard()),
                                          _buildBoardInstructions(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildControlPanelCompact(),
                              ],
                            )),
              ),
            ],
          ),
        ),
      ),
      if (userEmail != null)
        Positioned(
          top: 12,
          right: 12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Material(
              color: const Color(0xFF1E293B),
              elevation: 4,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 18,
                      color: Color(0xFF06B6D4),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        userEmail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Dang xuat',
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: _logout,
                        icon: const Icon(
                          Icons.logout,
                          size: 18,
                          color: Color(0xFFFCA5A5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFFF43F5E)],
          ).createShader(bounds),
          child: const Text(
            'CARO CHAMPION',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        const Text(
          'Ván cờ Trí Tuệ - Chơi 2 người Local & Online',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTurnIndicator() {
    String turnText = '';
    Color themeColor = Colors.white;

    if (isOnlineMode) {
      if (!isConnected) {
        turnText = 'Chưa kết nối';
      } else if (!isOpponentJoined) {
        turnText = 'Đang chờ đối thủ...';
        themeColor = Colors.amber;
      } else {
        final bool isMyTurn =
            (isXTurn && mySymbol == 'X') || (!isXTurn && mySymbol == 'O');
        if (isMyTurn) {
          turnText = 'Lượt của bạn ($mySymbol)';
          themeColor = mySymbol == 'X'
              ? const Color(0xFF06B6D4)
              : const Color(0xFFF43F5E);
        } else {
          final String oppSymbol = mySymbol == 'X' ? 'O' : 'X';
          turnText = 'Lượt đối thủ ($oppSymbol)';
          themeColor = const Color(0xFF94A3B8);
        }
      }
    } else {
      turnText = isXTurn
          ? 'Lượt đi: X (Người chơi X)'
          : 'Lượt đi: O (Người chơi O)';
      themeColor = isXTurn ? const Color(0xFF06B6D4) : const Color(0xFFF43F5E);
    }

    final bool isTimerActive =
        selectedTimerDuration > 0 &&
        (!isOnlineMode ? history.isNotEmpty : isOpponentJoined) &&
        !gameOver;
    final double progress = isTimerActive
        ? remainingTime / selectedTimerDuration
        : 1.0;
    final Color progressColor = progress > 0.5
        ? const Color(0xFF10B981) // Xanh lá
        : (progress > 0.25 ? Colors.amber : const Color(0xFFEF4444)); // Đỏ

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const Text(
                'Trạng thái: ',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColor, width: 1.5),
                ),
                child: Text(
                  turnText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          if (isTimerActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF0F172A),
                color: progressColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Text(
                  'Thời gian còn lại:',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                Text(
                  '$remainingTime giây',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cấu Hình Trận Đấu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kích thước bàn cờ:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildSizeSelectorChips(),
          const SizedBox(height: 12),
          const Text(
            'Thời gian mỗi lượt:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildTimerSelectorChips(),
        ],
      ),
    );
  }

  Widget _buildSizeSelectorChips() {
    final bool isInteractionBlocked = isOnlineMode && !isOpponentJoined;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: boardSizeOptions.map((option) {
        final int size = option['size'];
        final int win = option['win'];
        final String label = option['label'];
        final bool isSelected = boardSize == size && winCondition == win;

        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: const Color(0xFF06B6D4),
          backgroundColor: const Color(0xFF0F172A),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF06B6D4)
                  : const Color(0xFF334155),
              width: 1,
            ),
          ),
          onSelected: isInteractionBlocked
              ? null
              : (selected) {
                  if (selected) {
                    handleChangeSize(size, win);
                  }
                },
        );
      }).toList(),
    );
  }

  Widget _buildTimerSelectorChips() {
    final bool isInteractionBlocked = isOnlineMode && !isOpponentJoined;
    final options = [
      {'label': 'Vô hạn', 'value': 0},
      {'label': '15 giây', 'value': 15},
      {'label': '30 giây', 'value': 30},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final int val = option['value'] as int;
        final String label = option['label'] as String;
        final bool isSelected = selectedTimerDuration == val;

        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: const Color(0xFFEF4444),
          backgroundColor: const Color(0xFF0F172A),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF334155),
              width: 1,
            ),
          ),
          onSelected: isInteractionBlocked
              ? null
              : (selected) {
                  if (selected) {
                    handleTimerChange(val);
                  }
                },
        );
      }).toList(),
    );
  }

  Widget _buildBoardInstructions() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.zoom_in, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 6),
          Text(
            'Cuộn chuột/Bóp để Thu Phóng • Kéo chuột/Vuốt để di chuyển bàn cờ',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM KIỂM TRA THẮNG THUA & XỬ LÝ CLICK ---

  /// Kiểm tra xem có người chiến thắng chưa dựa trên nước đi mới nhất tại (row, col)
  List<List<int>>? checkWinner(int row, int col, String symbol) {
    final directions = [
      [0, 1],   // Ngang
      [1, 0],   // Dọc
      [1, 1],   // Chéo xuôi \
      [1, -1],  // Chéo ngược /
    ];

    for (final dir in directions) {
      int dRow = dir[0];
      int dCol = dir[1];
      List<List<int>> cells = [[row, col]];

      // Quét hướng tiến
      int r = row + dRow;
      int c = col + dCol;
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == symbol) {
        cells.add([r, c]);
        r += dRow;
        c += dCol;
      }

      // Quét hướng lùi
      r = row - dRow;
      c = col - dCol;
      while (r >= 0 && r < boardSize && c >= 0 && c < boardSize && board[r][c] == symbol) {
        cells.add([r, c]);
        r -= dRow;
        c -= dCol;
      }

      // Nếu số lượng ô cờ đạt điều kiện thắng
      if (cells.length >= winCondition) {
        return cells;
      }
    }
    return null;
  }

  /// Kiểm tra xem bàn cờ đã đầy hoàn toàn chưa (Hòa cờ)
  bool checkDraw() {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (board[r][c].isEmpty) {
          return false; // Vẫn còn ô trống
        }
      }
    }
    return true;
  }

  /// Xử lý chạm vào ô cờ
  void _handleCellTap(int row, int col) async {
    if (gameOver || board[row][col].isNotEmpty) return;

    if (isOnlineMode) {
      if (!isConnected || !isOpponentJoined) return;
      
      final bool isMyTurn = (isXTurn && mySymbol == 'X') || (!isXTurn && mySymbol == 'O');
      if (!isMyTurn) return;

      final Map<String, dynamic> newMove = {
        'row': row,
        'col': col,
        'symbol': mySymbol!,
      };
      
      final List<dynamic> newHistory = history.map((m) => <String, dynamic>{
        'row': m.row,
        'col': m.col,
        'symbol': m.symbol,
      }).toList()..add(newMove);

      board[row][col] = mySymbol!;
      final winningCombo = checkWinner(row, col, mySymbol!);
      final isDraw = checkDraw();
      board[row][col] = '';
      
      bool dbGameOver = false;
      List<List<int>> dbWinningCells = [];
      int dbXWins = xWins;
      int dbOWins = oWins;
      int dbDraws = draws;

      if (winningCombo != null) {
        dbGameOver = true;
        dbWinningCells = winningCombo;
        if (mySymbol == 'X') {
          dbXWins++;
        } else {
          dbOWins++;
        }
      } else if (isDraw) {
        dbGameOver = true;
        dbDraws++;
      }

      await supabase.from('rooms').update({
        'history': newHistory,
        'is_x_turn': !isXTurn,
        'last_move': {'row': row, 'col': col},
        'game_over': dbGameOver,
        'winning_cells': dbWinningCells,
        'x_wins': dbXWins,
        'o_wins': dbOWins,
        'draws': dbDraws,
        'last_action': 'move',
      }).eq('id', currentRoomId!);
    } else {
      final String currentSymbol = isXTurn ? 'X' : 'O';
      setState(() {
        board[row][col] = currentSymbol;
        lastMove = [row, col];
        history.add(Move(row: row, col: col, symbol: currentSymbol));
        suggestedCell = null;

        final winningCombo = checkWinner(row, col, currentSymbol);
        if (winningCombo != null) {
          _cancelTimer();
          winningCells = winningCombo;
          gameOver = true;
          if (currentSymbol == 'X') {
            xWins++;
          } else {
            oWins++;
          }
          _showEndGameDialog(
            'Chiến Thắng! 🎉',
            'Người chơi $currentSymbol đã giành chiến thắng thuyết phục!',
            currentSymbol,
          );
        } else if (checkDraw()) {
          _cancelTimer();
          gameOver = true;
          draws++;
          _showEndGameDialog(
            'Hòa Cờ! 🤝',
            'Hai bên đã hòa nhau trên bàn cờ đầy quân!',
            '',
          );
        } else {
          isXTurn = !isXTurn;
          _startTimer();
        }
      });
    }
  }

  // --- HÀM XÂY DỰNG CÁC DIALOG & UI PHÂN MẢNH ---

  /// Hiển thị hộp thoại kết thúc trận đấu
  void _showEndGameDialog(String title, String message, String winnerSymbol) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (winnerSymbol.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: winnerSymbol == 'X'
                          ? const Color(0xFF06B6D4).withOpacity(0.1)
                          : const Color(0xFFF43F5E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      winnerSymbol,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: winnerSymbol == 'X'
                            ? const Color(0xFF06B6D4)
                            : const Color(0xFFF43F5E),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    resetBoard();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Ván mới'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hiển thị hộp thoại khi đối thủ bị ngắt kết nối
  void _showOpponentDisconnectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Đối thủ đã thoát! 🔌', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: const Text(
            'Đối thủ của bạn đã ngắt kết nối khỏi phòng chơi này.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _disconnect();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
              ),
              child: const Text('Quay lại sảnh', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Xây dựng màn hình nhập mã phòng chơi Online
  Widget _buildConnectionScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CHƠI ONLINE REALTIME',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tạo phòng mới hoặc tham gia phòng chơi bằng mã 4 chữ số đồng bộ qua Supabase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              if (connectionError != null) ...[
                Text(
                  connectionError!,
                  style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: isConnecting ? null : () => _connectSupabase(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('TẠO PHÒNG MỚI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFF334155))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('HOẶC THAM GIA', style: TextStyle(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  const Expanded(child: Divider(color: Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Nhập Mã phòng (4 chữ số):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _roomIdController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Ví dụ: 8324',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: isConnecting
                    ? null
                    : () {
                        final room = _roomIdController.text.trim();
                        if (room.length == 4) {
                          _connectSupabase(false, joinRoomCode: room);
                        } else {
                          setState(() {
                            connectionError = 'Mã phòng phải có đúng 4 chữ số!';
                          });
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF43F5E),
                  side: const BorderSide(color: Color(0xFFF43F5E)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('THAM GIA PHÒNG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    isOnlineMode = false;
                    connectionError = null;
                  });
                },
                child: const Text('Quay lại chơi Local (Offline)', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng Bảng điểm tiêu chuẩn (Desktop)
  Widget _buildScoreboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bảng Tỉ Số',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreItem('X Thắng', xWins, const Color(0xFF06B6D4)),
              _buildScoreItem('Hòa', draws, const Color(0xFF94A3B8)),
              _buildScoreItem('O Thắng', oWins, const Color(0xFFF43F5E)),
            ],
          ),
        ],
      ),
    );
  }

  /// Xây dựng Bảng điểm thu gọn (Mobile)
  Widget _buildScoreboardCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('X Thắng: $xWins', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 12, fontWeight: FontWeight.bold)),
          const Text('|', style: TextStyle(color: Color(0xFF334155))),
          Text('Hòa: $draws', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
          const Text('|', style: TextStyle(color: Color(0xFF334155))),
          Text('O Thắng: $oWins', style: const TextStyle(color: Color(0xFFF43F5E), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  /// Xây dựng Panel Điều khiển chính (Desktop)
  Widget _buildControlPanel() {
    final bool isMyTurn = !isOnlineMode || (isXTurn && mySymbol == 'X') || (!isXTurn && mySymbol == 'O');
    final bool isUndoEnabled = history.isNotEmpty && !gameOver && isMyTurn && (!isOnlineMode || isOpponentJoined);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Điều Khiển',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isUndoEnabled ? undo : null,
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Đi Lại (Undo)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: resetBoard,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Ván Mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: resetAll,
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('Làm Mới Điểm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: suggestMove,
            icon: const Icon(Icons.lightbulb, size: 18),
            label: const Text('Gợi Ý Nước Đi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              if (isOnlineMode) {
                _disconnect();
              } else {
                setState(() {
                  isOnlineMode = true;
                });
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: isOnlineMode ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
              side: BorderSide(color: isOnlineMode ? const Color(0xFFEF4444) : const Color(0xFF06B6D4)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isOnlineMode ? 'Thoát Chế Độ Online' : 'Chơi Online'),
          ),
          if (isOnlineMode && isConnected) ...[
            const SizedBox(height: 8),
            Text(
              'Mã phòng: $currentRoomCode',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 15),
            ),
            Text(
              'Bạn cầm quân: $mySymbol',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  /// Xây dựng Panel Điều khiển thu gọn (Mobile)
  Widget _buildControlPanelCompact() {
    final bool isMyTurn = !isOnlineMode || (isXTurn && mySymbol == 'X') || (!isXTurn && mySymbol == 'O');
    final bool isUndoEnabled = history.isNotEmpty && !gameOver && isMyTurn && (!isOnlineMode || isOpponentJoined);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUndoEnabled ? undo : null,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Đi Lại', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: suggestMove,
                  icon: const Icon(Icons.lightbulb, size: 16),
                  label: const Text('Gợi Ý', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: resetBoard,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Ván Mới', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: resetAll,
                child: const Text('Reset Điểm', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (isOnlineMode) {
                    _disconnect();
                  } else {
                    setState(() {
                      isOnlineMode = true;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnlineMode ? const Color(0xFFEF4444) : const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isOnlineMode ? 'Thoát Online' : 'Chơi Online', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (isOnlineMode && isConnected) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Phòng: $currentRoomCode',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13),
                ),
                Text(
                  'Quân của bạn: $mySymbol',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Bảng luật chơi
  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Luật Chơi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            '• Người chơi lần lượt đánh X và O.\n'
            '• Để thắng, bạn cần đạt được số quân cờ liên tiếp theo hàng ngang, hàng dọc hoặc chéo như quy định (3 ô cho 3x3, 5 ô cho các cỡ khác).\n'
            '• Hỗ trợ chơi Local trên 1 máy hoặc Online thông qua mạng nội bộ Wifi.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Widget đại diện cho từng ô cờ đơn lẻ trên bàn cờ.
class BoardCell extends StatefulWidget {
  final int row;
  final int col;
  final String symbol;
  final bool isWinning;
  final bool isLastMove;
  final bool isSuggested;
  final String activePlayerSymbol;
  final double cellWidth;
  final VoidCallback onTap;

  const BoardCell({
    super.key,
    required this.row,
    required this.col,
    required this.symbol,
    required this.isWinning,
    required this.isLastMove,
    required this.isSuggested,
    required this.activePlayerSymbol,
    required this.cellWidth,
    required this.onTap,
  });

  @override
  State<BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<BoardCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color cellColor = const Color(0xFF1E293B);
    if (widget.isWinning) {
      cellColor = const Color(0x40F59E0B); // Vàng thắng cuộc
    } else if (widget.isSuggested) {
      cellColor = const Color(0x3310B981); // Xanh lá gợi ý AI
    } else if (widget.isLastMove) {
      cellColor = const Color(0xFF334155); // Xám nổi bật nước cuối
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cellColor,
            border: Border.all(
              color: widget.isWinning
                  ? const Color(0xFFF59E0B)
                  : (widget.isSuggested
                        ? const Color(0xFF10B981)
                        : (widget.isLastMove
                              ? const Color(0xFF06B6D4)
                              : const Color(0xFF334155))),
              width: widget.isWinning
                  ? 2.0
                  : (widget.isSuggested
                        ? 2.0
                        : (widget.isLastMove ? 1.5 : 0.5)),
            ),
          ),
          child: Center(
            child: widget.symbol.isNotEmpty
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: _buildPieceSymbol(widget.symbol),
                      );
                    },
                  )
                : (_isHovered
                      ? _buildPieceSymbol(
                          widget.activePlayerSymbol,
                          isHover: true,
                        )
                      : const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  Widget _buildPieceSymbol(String symbol, {bool isHover = false}) {
    final double opacity = isHover ? 0.25 : 1.0;
    final double fontSize = widget.cellWidth * 0.5;

    if (symbol == 'X') {
      return Text(
        'X',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF06B6D4).withOpacity(opacity),
          shadows: isHover
              ? null
              : [const Shadow(color: Color(0xAA06B6D4), blurRadius: 8)],
        ),
      );
    } else {
      return Text(
        'O',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF43F5E).withOpacity(opacity),
          shadows: isHover
              ? null
              : [const Shadow(color: Color(0xAAF43F5E), blurRadius: 8)],
        ),
      );
    }
  }
}
