import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const ProfilePage({super.key, this.supabaseClient});

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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
            ),
          ),
        ),
      ),
    );
  }
}
