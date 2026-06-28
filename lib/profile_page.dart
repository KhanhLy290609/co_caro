import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final int initialDiamonds;
  final List<String> initialUnlockedIcons;
  final String initialSelectedIcon;
  final Function(int diamonds, List<String> unlockedIcons, String selectedIcon)? onProfileUpdated;

  const ProfilePage({
    super.key, 
    this.supabaseClient,
    this.initialDiamonds = 0,
    this.initialUnlockedIcons = const ['X', 'O'],
    this.initialSelectedIcon = 'X',
    this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  late int _diamonds;
  late List<String> _unlockedIcons;
  late String _selectedIcon;

  final List<Map<String, dynamic>> _shopItems = [
    {'icon': '⭐', 'price': 5},
    {'icon': '🔥', 'price': 5},
    {'icon': '💧', 'price': 5},
    {'icon': '👑', 'price': 20},
    {'icon': '⚡', 'price': 20},
    {'icon': '🍀', 'price': 20},
    {'icon': '💎', 'price': 50},
    {'icon': '🚀', 'price': 50},
    {'icon': '👾', 'price': 50},
    {'icon': '🎯', 'price': 100},
    {'icon': '🐉', 'price': 100},
    {'icon': '🦄', 'price': 100},
  ];

  @override
  void initState() {
    super.initState();
    _diamonds = widget.initialDiamonds;
    _unlockedIcons = List<String>.from(widget.initialUnlockedIcons);
    _selectedIcon = widget.initialSelectedIcon;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _buyIcon(String icon, int price) async {
    if (_diamonds < price || _isLoading) return;
    
    final client = widget.supabaseClient ?? Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final newDiamonds = _diamonds - price;
    final newUnlocked = List<String>.from(_unlockedIcons)..add(icon);

    try {
      await client.from('profiles').update({
        'diamonds': newDiamonds,
        'unlocked_icons': newUnlocked,
      }).eq('id', user.id);

      setState(() {
        _diamonds = newDiamonds;
        _unlockedIcons = newUnlocked;
      });

      widget.onProfileUpdated?.call(_diamonds, _unlockedIcons, _selectedIcon);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mua thành công icon $icon! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xảy ra lỗi khi mua. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectIcon(String icon) async {
    if (_isLoading) return;

    final client = widget.supabaseClient ?? Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await client.from('profiles').update({
        'selected_icon': icon,
      }).eq('id', user.id);

      setState(() {
        _selectedIcon = icon;
      });

      widget.onProfileUpdated?.call(_diamonds, _unlockedIcons, _selectedIcon);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chọn cờ đại diện là $icon!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thay đổi quân cờ. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = widget.supabaseClient ?? Supabase.instance.client;

    try {
      final email = client.auth.currentUser?.email;
      if (email == null) {
        throw const AuthException('Không tìm thấy thông tin phiên đăng nhập. Vui lòng đăng nhập lại.');
      }

      // 1. Authenticate with current password
      await client.auth.signInWithPassword(
        email: email,
        password: _currentPasswordController.text,
      );

      // 2. Update to new password
      await client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.')),
        );
      }

      // 3. Log out and navigate back
      await client.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể đổi mật khẩu. Vui lòng thử lại.';
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
    String email = 'Chưa đăng nhập';
    try {
      final client = widget.supabaseClient ?? Supabase.instance.client;
      email = client.auth.currentUser?.email ?? 'Chưa đăng nhập';
    } catch (_) {
      // Supabase is not initialized (e.g. in tests)
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Trang cá nhân'),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD 1: Thông tin tài khoản & Kim cương
                  Card(
                    color: const Color(0xFF1E293B),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF0F172A),
                            child: Icon(Icons.person_rounded, color: Color(0xFF06B6D4)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tài khoản người chơi',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF06B6D4), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond_rounded, color: Color(0xFF06B6D4), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '$_diamonds',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 2: Chọn quân cờ sử dụng
                  Card(
                    color: const Color(0xFF1E293B),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF06B6D4), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Chọn quân cờ sử dụng',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _unlockedIcons.map((icon) {
                                final isSelected = _selectedIcon == icon;
                                return GestureDetector(
                                  onTap: isSelected || _isLoading ? null : () => _selectIcon(icon),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF06B6D4).withOpacity(0.1)
                                          : const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF334155),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          icon,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isSelected ? 'Đang dùng' : 'Chọn',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 3: Cửa hàng Icon quân cờ
                  Card(
                    color: const Color(0xFF1E293B),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.storefront_rounded, color: Color(0xFF06B6D4), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Cửa hàng Icon quân cờ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _shopItems.length,
                            itemBuilder: (context, index) {
                              final item = _shopItems[index];
                              final String iconSym = item['icon'];
                              final int price = item['price'];
                              final isOwned = _unlockedIcons.contains(iconSym);
                              final canAfford = _diamonds >= price;

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOwned ? const Color(0xFF334155) : const Color(0xFF1E293B),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(iconSym, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 8),
                                    if (isOwned)
                                      const Text(
                                        'Đã sở hữu',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    else
                                      ElevatedButton(
                                        onPressed: canAfford && !_isLoading ? () => _buyIcon(iconSym, price) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF06B6D4),
                                          disabledBackgroundColor: const Color(0xFF1E293B),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          minimumSize: const Size(64, 28),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.diamond_rounded, size: 12, color: Colors.white),
                                            const SizedBox(width: 2),
                                            Text(
                                              '$price',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 4: Đổi mật khẩu
                  Card(
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
                              Icons.lock_reset_rounded,
                              size: 48,
                              color: Color(0xFF06B6D4),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Đổi mật khẩu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrent,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu hiện tại',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Vui lòng nhập mật khẩu hiện tại';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNew,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu mới',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Vui lòng nhập mật khẩu mới';
                                }
                                if (value!.length < 6) {
                                  return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Nhập lại mật khẩu mới',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Vui lòng xác nhận mật khẩu mới';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Mật khẩu xác nhận không khớp!';
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
                              onPressed: _isLoading ? null : _changePassword,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.vpn_key),
                              label: Text(_isLoading ? 'Đang cập nhật...' : 'Đổi mật khẩu'),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
