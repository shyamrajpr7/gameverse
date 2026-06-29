import 'package:flutter/material.dart';
import '../models/game.dart';
import 'ui_enhancements.dart';

class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;
  final int index;

  const GameCard({super.key, required this.game, required this.onTap, this.index = 0});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _hoverController.forward();
    setState(() => _scale = 0.95);
  }

  void _onTapUp(_) {
    _hoverController.reverse();
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    _hoverController.reverse();
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.game.color;

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, _) {
        final glow = _hoverController.value;
        return GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Transform.scale(
              scale: 1.0 - (1.0 - _scale) * (1.0 + glow * 0.1),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.withValues(alpha: 0.2 + glow * 0.1),
                      c.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(
                    color: c.withValues(alpha: 0.25 + glow * 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.withValues(alpha: 0.08 + glow * 0.15),
                      blurRadius: 12 + glow * 12,
                      spreadRadius: glow * 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              c.withValues(alpha: 0.35 + glow * 0.15),
                              c.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: ShineEffect(
                            intensity: 0.1,
                            child: _AnimatedGameIcon(
                              icon: widget.game.icon,
                              color: c,
                              size: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.game.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9 + glow * 0.1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people, size: 12,
                                  color: Colors.white.withValues(alpha: 0.6)),
                              const SizedBox(width: 3),
                              Text(
                                _formatNumber(widget.game.playerCount),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 3),
                              Text(
                                widget.game.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6 + glow * 0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _AnimatedGameIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AnimatedGameIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedGameIcon> createState() => _AnimatedGameIconState();
}

class _AnimatedGameIconState extends State<_AnimatedGameIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final float = -4 * _controller.value;
        return Transform.translate(
          offset: Offset(0, float),
          child: Icon(widget.icon, size: widget.size, color: widget.color),
        );
      },
    );
  }
}

class FeaturedGameCard extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;

  const FeaturedGameCard({super.key, required this.game, required this.onTap});

  @override
  State<FeaturedGameCard> createState() => _FeaturedGameCardState();
}

class _FeaturedGameCardState extends State<FeaturedGameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        final glow = 0.3 + 0.3 * pulse;
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: size.width * 0.75,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  widget.game.color,
                  widget.game.color.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.game.color.withValues(alpha: glow),
                  blurRadius: 20 + 10 * pulse,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Transform.rotate(
                    angle: pulse * 0.1,
                    child: Icon(
                      widget.game.icon,
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.12 + 0.05 * pulse),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _AnimatedStarRating(rating: widget.game.rating),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Icon(widget.game.icon,
                                size: 24, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.game.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.game.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14,
                              color: Colors.white.withValues(alpha: 0.7)),
                          const SizedBox(width: 3),
                          Text(
                            '${_formatNumber(widget.game.playerCount)} playing',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(width: 16),
                          _buildXpBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildXpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars, size: 12,
              color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 3),
          Text(
            '+${widget.game.xpReward} XP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _AnimatedStarRating extends StatefulWidget {
  final double rating;
  const _AnimatedStarRating({required this.rating});

  @override
  State<_AnimatedStarRating> createState() => _AnimatedStarRatingState();
}

class _AnimatedStarRatingState extends State<_AnimatedStarRating>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 14,
              color: Colors.amber.withValues(alpha: 0.6 + 0.4 * _controller.value),
            ),
            const SizedBox(width: 3),
            Text(
              widget.rating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.7 + 0.3 * _controller.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryChip extends StatefulWidget {
  final GameCategory category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    required this.onTap,
  });

  @override
  State<CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category.color;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = widget.selected ? 0.3 + 0.2 * _pulseController.value : 0.0;
        return GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? c.withValues(alpha: 0.8 + glow * 0.2)
                  : c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: widget.selected
                    ? c
                    : c.withValues(alpha: 0.25),
                width: widget.selected ? 1.5 : 1,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: c.withValues(alpha: glow),
                        blurRadius: 10 + glow * 8,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.category.icon,
                  size: 18,
                  color: widget.selected ? Colors.white : c,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: widget.selected ? Colors.white : c,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
