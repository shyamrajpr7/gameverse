import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';
import '../utils/particle_system.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final Color color;
  final IconData icon;
  final String category;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.color,
    required this.icon,
    required this.category,
  });
}

const List<ShopItem> shopItems = [
  ShopItem(
    id: 'theme_crimson',
    name: 'Crimson Red',
    description: 'A bold red accent theme',
    cost: 100,
    color: Color(0xFFE53935),
    icon: Icons.colorize,
    category: 'theme',
  ),
  ShopItem(
    id: 'theme_neon_blue',
    name: 'Neon Blue',
    description: 'Electric blue neon glow',
    cost: 100,
    color: Color(0xFF00BCD4),
    icon: Icons.colorize,
    category: 'theme',
  ),
  ShopItem(
    id: 'theme_forest_green',
    name: 'Forest Green',
    description: 'Deep natural green tones',
    cost: 100,
    color: Color(0xFF43A047),
    icon: Icons.colorize,
    category: 'theme',
  ),
  ShopItem(
    id: 'snake_rainbow',
    name: 'Rainbow Skin',
    description: 'Cycling rainbow colors for your snake',
    cost: 200,
    color: Color(0xFFFFD700),
    icon: Icons.palette,
    category: 'snake',
  ),
  ShopItem(
    id: 'snake_cyberpunk',
    name: 'Cyberpunk Grid',
    description: 'Neon grid pattern snake skin',
    cost: 150,
    color: Color(0xFF6C5CE7),
    icon: Icons.grid_on,
    category: 'snake',
  ),
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  final ParticleEmitter _emitter = ParticleEmitter();
  late AnimationController _coinPulseController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _coinPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    await _gameService.load();
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _coinPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildCoinBalance()),
          SliverToBoxAdapter(child: _buildSectionHeader('Themes', Icons.palette_outlined)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildItemsGrid(shopItems.where((i) => i.category == 'theme').toList()),
            ),
          ),
          SliverToBoxAdapter(child: _buildSectionHeader('Snake Skins', Icons.auto_awesome)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: _buildItemsGrid(shopItems.where((i) => i.category == 'snake').toList()),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0F0F23),
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white70),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag, color: Color(0xFFFFD700), size: 22),
          SizedBox(width: 8),
          Text('Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(color: const Color(0xFFFFD700).withValues(alpha: 0.2), height: 1),
      ),
    );
  }

  Widget _buildCoinBalance() {
    return AnimatedBuilder(
      animation: _coinPulseController,
      builder: (context, _) {
        final pulse = 0.85 + 0.15 * _coinPulseController.value;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.1),
                const Color(0xFFFF8C00).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3 * pulse),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.monetization_on, color: Colors.black87, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_gameService.coins}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'coins',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(List<ShopItem> items) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShopItemCard(
          item: item,
          gameService: _gameService,
          emitter: _emitter,
          onChanged: () => setState(() {}),
        ),
      )).toList(),
    );
  }
}

class _ShopItemCard extends StatefulWidget {
  final ShopItem item;
  final GameService gameService;
  final ParticleEmitter emitter;
  final VoidCallback onChanged;

  const _ShopItemCard({
    required this.item,
    required this.gameService,
    required this.emitter,
    required this.onChanged,
  });

  @override
  State<_ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<_ShopItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _previewController;

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  bool get _isUnlocked => widget.gameService.isCosmeticUnlocked(widget.item.id);

  bool get _isEquipped {
    if (widget.item.category == 'snake') {
      return widget.gameService.equippedSnakeSkin == widget.item.id;
    }
    return widget.gameService.equippedTheme == widget.item.id;
  }

  Future<void> _buy() async {
    final success = await widget.gameService.spendCoins(widget.item.cost);
    if (!mounted) return;
    if (success) {
      await widget.gameService.updateQuestProgress(
        QuestTargetType.spendCoins,
        widget.item.cost,
      );
      await widget.gameService.unlockCosmetic(widget.item.id);
      AudioService().play(SoundType.achievement);
      HapticService.medium();
      widget.onChanged();

      if (mounted) {
        _showBuySuccess();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Not enough coins!'),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            behavior: SnackBarBehavior.floating,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    }
  }

  Future<void> _showBuySuccess() async {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: _BuySuccessDialog(
          item: widget.item,
          emitter: widget.emitter,
          onDone: () {
            if (mounted) {
              widget.onChanged();
            }
          },
        ),
      ),
    );
  }

  Future<void> _equip() async {
    await widget.gameService.equipCosmetic(widget.item.id);
    AudioService().play(SoundType.click);
    HapticService.light();
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.name} equipped!'),
          backgroundColor: widget.item.color.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEquipped
              ? widget.item.color.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildPreview(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.item.id == 'snake_rainbow') {
      return AnimatedBuilder(
        animation: _previewController,
        builder: (context, _) {
          final hue = _previewController.value * 360;
          final color = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
          return _previewContainer(LinearGradient(colors: [color, color]));
        },
      );
    }
    if (widget.item.id == 'snake_cyberpunk') {
      return AnimatedBuilder(
        animation: _previewController,
        builder: (context, _) {
          final shift = math.sin(_previewController.value * math.pi * 2) * 10;
          return _previewContainer(
            LinearGradient(
              colors: const [Color(0xFF6C5CE7), Color(0xFF00BCD4)],
              begin: Alignment.topLeft + Alignment(shift / 100, 0),
              end: Alignment.bottomRight,
            ),
          );
        },
      );
    }
    return _previewContainer(LinearGradient(
      colors: [widget.item.color, widget.item.color.withValues(alpha: 0.6)],
    ));
  }

  Widget _previewContainer(Gradient gradient) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: gradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: Icon(widget.item.icon, color: Colors.white.withValues(alpha: 0.7), size: 24),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: widget.item.color.withValues(alpha: 0.15),
          border: Border.all(color: widget.item.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: widget.item.color, size: 16),
            const SizedBox(width: 4),
            Text('Equipped', style: TextStyle(color: widget.item.color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_isUnlocked) {
      return GestureDetector(
        onTap: _equip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.item.color.withValues(alpha: 0.2),
          ),
          child: Text('Equip', style: TextStyle(color: widget.item.color, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return GestureDetector(
      onTap: _buy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 4),
            Text('${widget.item.cost}', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _BuySuccessDialog extends StatefulWidget {
  final ShopItem item;
  final ParticleEmitter emitter;
  final VoidCallback onDone;

  const _BuySuccessDialog({
    required this.item,
    required this.emitter,
    required this.onDone,
  });

  @override
  State<_BuySuccessDialog> createState() => _BuySuccessDialogState();
}

class _BuySuccessDialogState extends State<_BuySuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _emitParticles();
  }

  void _emitParticles() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final center = MediaQuery.of(context).size.center(Offset.zero);
        widget.emitter.emitBurst(
          position: center,
          color: widget.item.color,
          baseSpeed: 200,
          lifespan: 0.8,
        );
        widget.emitter.emit(
          position: center,
          count: 20,
          color: const Color(0xFFFFD700),
          speed: 150,
          spread: 2 * math.pi,
          minSize: 3,
          maxSize: 7,
          type: ParticleType.star,
          lifespan: 0.7,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F23),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.item.color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.item.color.withValues(alpha: 0.2),
                ),
                child: Icon(widget.item.icon, color: widget.item.color, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Purchased!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                widget.item.name,
                style: TextStyle(fontSize: 16, color: widget.item.color),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDone();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.item.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Game preview helper - used by the shop to render small previews of items
mixin GamePreview {
  static Widget themePreview(Color color, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
      ),
    );
  }

  static Widget snakePreview(Color baseColor, {double size = 56}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SnakePreviewPainter(color: baseColor),
    );
  }
}

class _SnakePreviewPainter extends CustomPainter {
  final Color color;

  _SnakePreviewPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.2,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.6, size.height * 0.8,
      size.width * 0.8, size.height * 0.5,
    );
    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.5),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
