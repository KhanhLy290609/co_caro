// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'dart:async';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocusNode.dispose();
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
        _errorMessage = 'Không thể đăng nhập. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không khớp!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null) {
        // Luôn đăng xuất để bắt người dùng tự đăng nhập lại
        await _supabase.auth.signOut();

        if (response.session == null) {
          // Email confirmation is required by Supabase
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Đăng ký thành công'),
              content: const Text(
                'Một email xác nhận đã được gửi đến địa chỉ của bạn. Vui lòng kiểm tra và xác thực tài khoản trước khi đăng nhập.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isSignUp = false;
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: const Text('Đồng ý'),
                ),
              ],
            ),
          );
        } else {
          // Session was active, but we logged out
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Đăng ký thành công'),
              content: const Text(
                'Đăng ký tài khoản thành công! Vui lòng đăng nhập lại bằng tài khoản mới của bạn.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isSignUp = false;
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: const Text('Đồng ý'),
                ),
              ],
            ),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể đăng ký. Vui lòng thử lại sau.';
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
                        Text(
                          _isSignUp ? 'Đăng ký tài khoản' : 'Đăng nhập',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignUp
                              ? 'Tạo tài khoản mới để chơi game Caro trực tuyến.'
                              : 'Sử dụng email và mật khẩu của bạn để vào game.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF94A3B8)),
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
                              return 'Vui lòng nhập email';
                            }
                            if (!email.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (_isSignUp) {
                              FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                            } else {
                              _login();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
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
                              return 'Vui lòng nhập mật khẩu';
                            }
                            return null;
                          },
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          firstCurve: Curves.easeInOut,
                          secondCurve: Curves.easeInOut,
                          crossFadeState: _isSignUp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signUp(),
                              decoration: InputDecoration(
                                labelText: 'Nhập lại mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (!_isSignUp) return null;
                                if ((value ?? '').isEmpty) {
                                  return 'Vui lòng xác nhận mật khẩu';
                                }
                                if (value != _passwordController.text) {
                                  return 'Mật khẩu xác nhận không khớp!';
                                }
                                return null;
                              },
                            ),
                          ),
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
                          onPressed: _isLoading ? null : (_isSignUp ? _signUp : _login),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_isSignUp ? Icons.person_add : Icons.login),
                          label: Text(
                            _isLoading
                                ? (_isSignUp ? 'Đang đăng ký...' : 'Đang đăng nhập...')
                                : (_isSignUp ? 'Đăng ký' : 'Đăng nhập'),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _errorMessage = null;
                                    _passwordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                          child: Text(
                            _isSignUp ? 'Đã có tài khoản? Đăng nhập ngay' : 'Chưa có tài khoản? Đăng ký ngay',
                            style: const TextStyle(
                              color: Color(0xFF06B6D4),
                              fontWeight: FontWeight.w600,
                            ),
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

  // Trạng thái hiển thị pháo hoa khi chiến thắng
  bool _showFireworks = false;

  // --- Các biến phục vụ chế độ đấu với máy (Bot AI) ---
  bool isVSBot = false; // Có đang chơi với máy không
  bool isBotEasy = true; // Độ khó của máy (true: Dễ, false: Khó)
  bool _isBotThinking = false; // Trạng thái máy đang suy nghĩ

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
    _isBotThinking = false;
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
      
      // Nếu có đường cờ thắng cuộc, kích hoạt pháo hoa 5s trước khi hiện Dialog hỏi ván mới
      if (winningCells.isNotEmpty) {
        setState(() {
          _showFireworks = true;
        });
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _showFireworks = false;
            });
            _showEndGameDialog(title, message, winnerSymbol);
          }
        });
      } else {
        _showEndGameDialog(title, message, winnerSymbol);
      }
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
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _disconnect(updateState: false);
      await Supabase.instance.client.auth.signOut();
    }
  }

  void _executeLocalUndo() {
    if (history.isEmpty || gameOver) return;
    setState(() {
      // Nếu đấu với máy và có từ 2 nước cờ trở lên, lùi lại 2 nước (nước máy và nước người chơi)
      if (isVSBot && history.length >= 2) {
        final lastBotMove = history.removeLast();
        board[lastBotMove.row][lastBotMove.col] = '';
        
        final lastUserMove = history.removeLast();
        board[lastUserMove.row][lastUserMove.col] = '';
        
        isXTurn = true; // Luôn trả lượt cho người chơi
      } else {
        // Chế độ 2 người chơi hoặc khi lịch sử chỉ có 1 nước cờ
        final last = history.removeLast();
        board[last.row][last.col] = '';
        isXTurn = !isXTurn;
      }
      
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

  /// Lấy nước đi của Bot dựa theo độ khó (Dễ hoặc Khó)
  List<int>? _getBotMove() {
    if (isBotEasy) {
      // ==================== CHẾ ĐỘ DỄ ====================
      // Ý tưởng: Đánh giá tất cả các ô ứng viên giống như chế độ Khó,
      // nhưng sẽ chọn nước đi tốt thứ nhất với xác suất 50%, 
      // nước đi tốt thứ hai với xác suất 35%, và nước đi tốt thứ ba với xác suất 15%.
      // Điều này làm Bot vẫn biết tấn công/phòng thủ nhưng thỉnh thoảng mắc sai lầm để người dùng thắng.
      
      final String mySym = 'O';
      final String oppSym = 'X';
      
      // Tạo danh sách các ứng viên ô trống trong bán kính 2 ô xung quanh các quân đã đánh
      List<Map<String, dynamic>> candidates = [];
      
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (board[r][c].isEmpty) {
            if (_hasNeighbor(r, c)) {
              final int attackScore = _evaluateCellForSymbol(r, c, mySym);
              final int defenseScore = _evaluateCellForSymbol(r, c, oppSym);
              final int totalScore = attackScore + defenseScore;
              candidates.add({
                'row': r,
                'col': c,
                'score': totalScore,
              });
            }
          }
        }
      }
      
      if (candidates.isEmpty) {
        return [boardSize ~/ 2, boardSize ~/ 2];
      }
      
      // Sắp xếp các ứng viên theo tổng điểm giảm dần
      candidates.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      final double randomValue = Random().nextDouble();
      
      if (randomValue < 0.50 || candidates.length < 2) {
        // 50% chọn nước đi tối ưu nhất
        return [candidates[0]['row'] as int, candidates[0]['col'] as int];
      } else if (randomValue < 0.85 || candidates.length < 3) {
        // 35% chọn nước đi tốt thứ hai
        return [candidates[1]['row'] as int, candidates[1]['col'] as int];
      } else {
        // 15% chọn nước đi tốt thứ ba
        return [candidates[2]['row'] as int, candidates[2]['col'] as int];
      }
    } else {
      // ==================== CHẾ ĐỘ KHÓ ====================
      // Luôn luôn chọn nước đi Heuristic tối ưu nhất
      return _getAIMoveSuggestion();
    }
  }

  /// Kích hoạt di chuyển cho Bot với độ trễ 0.5 giây
  void _triggerBotMove() {
    if (gameOver || _isBotThinking) return;

    setState(() {
      _isBotThinking = true;
    });

    // Trì hoãn 500ms (0.5 giây)
    Timer(const Duration(milliseconds: 500), () {
      if (!mounted || gameOver || isXTurn) {
        if (mounted) {
          setState(() {
            _isBotThinking = false;
          });
        }
        return;
      }

      final botMove = _getBotMove();
      if (botMove != null) {
        final int r = botMove[0];
        final int c = botMove[1];

        setState(() {
          board[r][c] = 'O';
          lastMove = [r, c];
          history.add(Move(row: r, col: c, symbol: 'O'));
          suggestedCell = null;
          _isBotThinking = false;

          final winningCombo = checkWinner(r, c, 'O');
          if (winningCombo != null) {
            _cancelTimer();
            winningCells = winningCombo;
            gameOver = true;
            oWins++;
            
            // Kích hoạt pháo hoa
            _showFireworks = true;

            // Hẹn giờ 5 giây hiển thị pháo hoa, sau đó hiện Dialog kết quả
            Timer(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showFireworks = false;
                });
                _showEndGameDialog(
                  'Thất Bại! 😢',
                  'Máy (quân O) đã giành chiến thắng ván cờ này!',
                  'O',
                );
              }
            });
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
            isXTurn = true;
            _startTimer();
          }
        });
      } else {
        setState(() {
          _isBotThinking = false;
        });
      }
    });
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
      } else if (count == winCondition - 1) {
        if (openEnds == 2) {
          totalScore += 150000; // Gần thắng hai đầu mở (cực kỳ nguy hiểm)
        } else if (openEnds == 1) {
          totalScore += 20000; // Gần thắng bị chặn 1 đầu
        }
      } else if (count == winCondition - 2) {
        if (openEnds == 2) {
          totalScore += 10000; // 3 quân thoáng 2 đầu
        } else if (openEnds == 1) {
          totalScore += 2000; // 3 quân chặn 1 đầu
        }
      } else if (count == winCondition - 3) {
        if (openEnds == 2) {
          totalScore += 1000;
        } else if (openEnds == 1) {
          totalScore += 200;
        }
      } else if (count == winCondition - 4) {
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
                    Flexible(
                      child: Tooltip(
                        message: 'Xem thông tin cá nhân / Đổi mật khẩu',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                              ],
                            ),
                          ),
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
        if (_showFireworks)
          const IgnorePointer(
            child: FireworksOverlay(),
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
      if (isVSBot) {
        if (isXTurn) {
          turnText = 'Lượt của bạn (X)';
          themeColor = const Color(0xFF06B6D4);
        } else {
          turnText = 'Máy đang suy nghĩ... (O)';
          themeColor = const Color(0xFFF43F5E);
        }
      } else {
        turnText = isXTurn
            ? 'Lượt đi: X (Người chơi X)'
            : 'Lượt đi: O (Người chơi O)';
        themeColor = isXTurn ? const Color(0xFF06B6D4) : const Color(0xFFF43F5E);
      }
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
          _buildGameModeSelector(),
          if (isVSBot && !isOnlineMode) ...[
            const SizedBox(height: 12),
            _buildDifficultySelector(),
          ],
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
          _buildBoardSizeSlider(),
          const SizedBox(height: 12),
          const Text(
            'Số quân liên tiếp để thắng:',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildWinConditionSelectorChips(),
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

  Widget _buildGameModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chế độ chơi:',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        isOnlineMode
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.online_prediction, color: Color(0xFF06B6D4), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Đấu Online Realtime (PVP)',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  ChoiceChip(
                    label: const Text('2 người'),
                    selected: !isVSBot,
                    selectedColor: const Color(0xFF06B6D4),
                    backgroundColor: const Color(0xFF0F172A),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          isVSBot = false;
                          _initGameData();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Đấu với máy'),
                    selected: isVSBot,
                    selectedColor: const Color(0xFF06B6D4),
                    backgroundColor: const Color(0xFF0F172A),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          isVSBot = true;
                          _initGameData();
                        });
                      }
                    },
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Độ khó của máy:',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Dễ'),
              selected: isBotEasy,
              selectedColor: Colors.amber,
              backgroundColor: const Color(0xFF0F172A),
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    isBotEasy = true;
                    _initGameData();
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Khó'),
              selected: !isBotEasy,
              selectedColor: const Color(0xFFF43F5E),
              backgroundColor: const Color(0xFF0F172A),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    isBotEasy = false;
                    _initGameData();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoardSizeSlider() {
    final bool isInteractionBlocked = isOnlineMode && !isOpponentJoined;

    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF06B6D4),
              inactiveTrackColor: const Color(0xFF0F172A),
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              thumbColor: const Color(0xFF06B6D4),
              overlayColor: const Color(0xFF06B6D4).withAlpha(32),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              tickMarkShape: const RoundSliderTickMarkShape(),
              activeTickMarkColor: const Color(0xFF06B6D4),
              inactiveTickMarkColor: const Color(0xFF334155),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: const Color(0xFF06B6D4),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
              ),
            ),
            child: Slider(
              value: boardSize.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              label: '${boardSize}x$boardSize',
              onChanged: isInteractionBlocked
                  ? null
                  : (double value) {
                      setState(() {
                        boardSize = value.round();
                        if (boardSize < winCondition) {
                          if (boardSize >= 7) {
                            // Keep
                          } else if (boardSize >= 5) {
                            winCondition = 5;
                          } else {
                            winCondition = 3;
                          }
                        }
                        _initGameData();
                      });
                    },
              onChangeEnd: isInteractionBlocked
                  ? null
                  : (double value) {
                      handleChangeSize(boardSize, winCondition);
                    },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            '${boardSize}x$boardSize',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF06B6D4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinConditionSelectorChips() {
    final bool isInteractionBlocked = isOnlineMode && !isOpponentJoined;
    final options = [3, 5, 7];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((winVal) {
        final bool isSelected = winCondition == winVal;
        final bool isEnabled = boardSize >= winVal;

        return ChoiceChip(
          label: Text(
            '$winVal quân',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isEnabled ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
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
          onSelected: isInteractionBlocked || !isEnabled
              ? null
              : (selected) {
                  if (selected) {
                    handleChangeSize(boardSize, winVal);
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
    
    // Nếu đang đấu với máy và không phải lượt của X (người chơi) hoặc máy đang suy nghĩ, chặn không cho đánh
    if (!isOnlineMode && isVSBot && (!isXTurn || _isBotThinking)) return;

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
          
          // Kích hoạt pháo hoa
          setState(() {
            _showFireworks = true;
          });

          // Hẹn giờ 5 giây hiển thị pháo hoa và ô cờ nổi bật nhấp nháy, sau đó mới hiện Dialog hỏi ván mới
          Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _showFireworks = false;
              });
              _showEndGameDialog(
                'Chiến Thắng! 🎉',
                'Người chơi $currentSymbol đã giành chiến thắng thuyết phục!',
                currentSymbol,
              );
            }
          });
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

          // Nếu đang chơi chế độ Đấu với máy và vừa kết thúc lượt đi của X (người chơi), kích hoạt Bot di chuyển
          if (isVSBot && !isXTurn) {
            _triggerBotMove();
          }
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
                  isVSBot = false; // Tắt đấu với máy khi chơi Online
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
                      isVSBot = false; // Tắt đấu với máy khi chơi Online
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Luật Chơi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '• Người chơi lần lượt đánh X và O.\n'
            '• Để thắng, bạn cần đạt được $winCondition quân cờ liên tiếp theo hàng ngang, hàng dọc hoặc chéo.\n'
            '• Hỗ trợ chơi Local trên 1 máy hoặc Online thông qua mạng nội bộ Wifi.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.5),
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

class _BoardCellState extends State<BoardCell> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo AnimationController để điều khiển hiệu ứng nhấp nháy của ô thắng cuộc
    // chu kỳ nhấp nháy là 1000ms (1 giây)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Tạo hiệu ứng nhấp nháy tuần hoàn nhẹ nhàng (độ mờ từ 1.0 về 0.4 rồi lặp lại)
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _blinkController,
        curve: Curves.easeInOut,
      ),
    );

    // Nếu lúc vẽ ô này đã thuộc nhóm thắng cuộc, kích hoạt nhấp nháy ngay lập tức
    if (widget.isWinning) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BoardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kích hoạt hiệu ứng nhấp nháy khi trạng thái thắng cuộc được bật
    if (widget.isWinning && !oldWidget.isWinning) {
      _blinkController.repeat(reverse: true);
    }
    // Dừng hiệu ứng khi reset bàn cờ hoặc tắt trạng thái thắng cuộc
    else if (!widget.isWinning && oldWidget.isWinning) {
      _blinkController.stop();
      _blinkController.value = 0.0; // Đưa về trạng thái hiển thị rõ nét mặc định
    }
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên cho AnimationController để tránh rò rỉ bộ nhớ
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Thiết lập màu sắc và đường viền mặc định
    Color cellColor = const Color(0xFF1E293B);
    Color borderColor = const Color(0xFF334155);
    double borderWidth = 0.5;

    // Thay đổi giao diện dựa trên trạng thái của ô cờ
    if (widget.isWinning) {
      // Khi thắng cuộc: Đổi sang màu của người thắng cuộc (X: xanh cyan, O: đỏ rose)
      final Color winnerColor = (widget.symbol == 'X')
          ? const Color(0xFF06B6D4)
          : const Color(0xFFF43F5E);
      cellColor = winnerColor.withOpacity(0.35);
      borderColor = winnerColor;
      borderWidth = 2.5;
    } else if (widget.isSuggested) {
      // Khi được gợi ý nước đi: Đổi sang màu xanh lá
      cellColor = const Color(0x3310B981);
      borderColor = const Color(0xFF10B981);
      borderWidth = 2.0;
    } else if (widget.isLastMove) {
      // Nước đi vừa đánh: Nổi bật với màu xám đậm và viền Cyan xanh lam
      cellColor = const Color(0xFF334155);
      borderColor = const Color(0xFF06B6D4);
      borderWidth = 1.5;
    }

    Widget cellContent;
    if (widget.symbol.isNotEmpty) {
      if (widget.isWinning) {
        // Đối với ô thắng cuộc, phóng to riêng quân cờ (X hoặc O) lên 1.25 lần để nổi bật
        cellContent = Transform.scale(
          scale: 1.25,
          child: _buildPieceSymbol(widget.symbol),
        );
      } else if (widget.isLastMove) {
        // CHỈ nước đi vừa đánh (isLastMove) mới có hiệu ứng phóng to trong 200ms
        cellContent = TweenAnimationBuilder<double>(
          key: ValueKey('animate_${widget.row}_${widget.col}_${widget.symbol}'),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 200), // Thời lượng đúng 200ms
          curve: Curves.easeOutBack, // Hiệu ứng đàn hồi nhẹ tạo sự sống động
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildPieceSymbol(widget.symbol),
            );
          },
        );
      } else {
        // Các ô cờ cũ khác vẽ tĩnh hoàn toàn để tối ưu hiệu suất, tránh giật lag khi có 400 ô
        cellContent = _buildPieceSymbol(widget.symbol);
      }
    } else if (_isHovered) {
      // Hiển thị quân cờ mờ xem trước khi rê chuột qua ô trống
      cellContent = _buildPieceSymbol(widget.activePlayerSymbol, isHover: true);
    } else {
      cellContent = const SizedBox.shrink();
    }

    Widget boardCellWidget = Container(
      decoration: BoxDecoration(
        color: cellColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Center(
        child: cellContent,
      ),
    );

    // Nếu ô cờ thuộc đường thắng cuộc, bọc trong FadeTransition để thực hiện nhấp nháy nhẹ
    if (widget.isWinning) {
      boardCellWidget = FadeTransition(
        opacity: _blinkAnimation,
        child: boardCellWidget,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: boardCellWidget,
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

// ==================== HỆ THỐNG PHÁO HOA TỰ BẮN KHI CHIẾN THẮNG ====================

/// Đại diện cho một hạt tia lửa pháo hoa
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double alpha = 1.0;
  double life; // Tuổi thọ hạt (giảm dần từ 1.0 về 0.0)

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });

  void update() {
    x += vx;
    y += vy;
    vy += 0.12; // Lực trọng trường kéo các tia rơi xuống nhẹ nhàng
    vx *= 0.98; // Lực cản không khí
    vy *= 0.98;
    life -= 0.015; // Giảm dần tuổi thọ hạt sau mỗi khung hình
    if (life < 0) life = 0;
    alpha = life;
  }
}

/// Đại diện cho một phát bắn pháo hoa từ dưới đất lên rồi nổ tung
class Firework {
  double centerX;
  double centerY;
  List<Particle> particles = [];
  bool exploded = false;
  double vy = -12.0; // Tốc độ bắn lên ban đầu
  double currentY;

  Firework(double screenWidth, double screenHeight)
      : centerX = Random().nextDouble() * screenWidth,
        centerY = screenHeight,
        currentY = screenHeight;

  void update() {
    if (!exploded) {
      currentY += vy;
      vy += 0.18; // Trọng lực làm giảm dần vận tốc bay lên
      if (vy >= -1.5) {
        explode();
      }
    } else {
      for (final p in particles) {
        p.update();
      }
      particles.removeWhere((p) => p.life <= 0);
    }
  }

  void explode() {
    exploded = true;
    final random = Random();
    final int particleCount = 45 + random.nextInt(25); // Số tia pháo nổ ra (từ 45 - 70 tia)
    
    // Tạo màu ngẫu nhiên rực rỡ từ bảng màu HSV
    final Color color = HSVColor.fromAHSV(
      1.0,
      random.nextDouble() * 360,
      0.85,
      1.0,
    ).toColor();

    for (int i = 0; i < particleCount; i++) {
      final double angle = random.nextDouble() * 2 * pi;
      final double speed = 1.5 + random.nextDouble() * 5.5;
      particles.add(Particle(
        x: centerX,
        y: currentY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        size: 2.5 + random.nextDouble() * 3.5,
        life: 1.0,
      ));
    }
  }

  bool get isDone => exploded && particles.isEmpty;
}

/// Widget phủ toàn màn hình dùng để cập nhật và vẽ pháo hoa
class FireworksOverlay extends StatefulWidget {
  const FireworksOverlay({super.key});

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Firework> _fireworks = [];
  final Random _random = Random();
  double _width = 0;
  double _height = 0;

  @override
  void initState() {
    super.initState();
    // Khởi tạo vòng lặp animation bằng cách sử dụng Ticker của AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        _updatePhysics();
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePhysics() {
    if (_width == 0 || _height == 0) return;

    // Tỉ lệ bắn pháo hoa ngẫu nhiên sau mỗi khung hình (tối đa 6 quả pháo cùng lúc)
    if (_random.nextDouble() < 0.06 && _fireworks.length < 6) {
      _fireworks.add(Firework(_width, _height));
    }

    setState(() {
      for (final fw in _fireworks) {
        fw.update();
      }
      _fireworks.removeWhere((fw) => fw.isDone);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        _height = constraints.maxHeight;
        return CustomPaint(
          size: Size.infinite,
          painter: FireworksPainter(_fireworks),
        );
      },
    );
  }
}

/// CustomPainter chuyên biệt để vẽ pháo hoa với hiệu năng cực cao
class FireworksPainter extends CustomPainter {
  final List<Firework> fireworks;

  FireworksPainter(this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final fw in fireworks) {
      if (!fw.exploded) {
        // Vẽ quả pháo đang bay lên có màu trắng/vàng sáng
        paint.color = const Color(0xFFFEF08A);
        canvas.drawCircle(Offset(fw.centerX, fw.currentY), 3.5, paint);
      } else {
        // Vẽ các tia lửa bắn ra sau khi nổ tung
        for (final p in fw.particles) {
          paint.color = p.color.withOpacity(p.alpha);
          canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
