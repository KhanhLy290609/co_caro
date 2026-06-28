import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  final int initialDiamonds;
  final List<String> initialUnlockedIcons;
  final String initialSelectedIcon;
  final bool useDatabaseTable;
  final Function(int diamonds, List<String> unlockedIcons, String selectedIcon)? onProfileUpdated;

  const ShopPage({
    super.key, 
    this.supabaseClient,
    this.initialDiamonds = 0,
    this.initialUnlockedIcons = const ['X', 'O'],
    this.initialSelectedIcon = 'X',
    this.useDatabaseTable = true,
    this.onProfileUpdated,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  bool _isLoading = false;
  late int _diamonds;
  late List<String> _unlockedIcons;
  late String _selectedIcon;
  late bool _useDatabaseTable;

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
    _useDatabaseTable = widget.useDatabaseTable;
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

    if (_useDatabaseTable) {
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
        setState(() => _isLoading = false);
        return;
      } catch (e) {
        print('Lỗi mua icon từ DB, chuyển sang fallback userMetadata: $e');
        _useDatabaseTable = false;
      }
    }

    // Fallback: update user metadata
    try {
      await client.auth.updateUser(UserAttributes(
        data: {
          'diamonds': newDiamonds,
          'unlocked_icons': newUnlocked,
          'selected_icon': _selectedIcon,
        },
      ));

      setState(() {
        _diamonds = newDiamonds;
        _unlockedIcons = newUnlocked;
      });

      widget.onProfileUpdated?.call(_diamonds, _unlockedIcons, _selectedIcon);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mua thành công icon $icon! 🎉 (Metadata)')),
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

    if (_useDatabaseTable) {
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
        setState(() => _isLoading = false);
        return;
      } catch (e) {
        print('Lỗi chọn icon từ DB, chuyển sang fallback userMetadata: $e');
        _useDatabaseTable = false;
      }
    }

    // Fallback: update user metadata
    try {
      await client.auth.updateUser(UserAttributes(
        data: {
          'diamonds': _diamonds,
          'unlocked_icons': _unlockedIcons,
          'selected_icon': icon,
        },
      ));

      setState(() {
        _selectedIcon = icon;
      });

      widget.onProfileUpdated?.call(_diamonds, _unlockedIcons, _selectedIcon);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chọn cờ đại diện là $icon! (Metadata)')),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.supabaseClient ?? Supabase.instance.client;
    final email = client.auth.currentUser?.email ?? 'Chưa đăng nhập';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Cửa hàng Icon'),
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
                  // CARD 1: Số dư Kim cương
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
                            child: Icon(Icons.storefront_rounded, color: Color(0xFF06B6D4)),
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
                                  'Cửa hàng vật phẩm',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
