import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ShareResult {
  final Uint8List pngBytes;
  final String filePath;
  ShareResult({required this.pngBytes, required this.filePath});
}

class ShareService {
  static final ShareService _instance = ShareService._();
  factory ShareService() => _instance;
  ShareService._();

  final GlobalKey repaintKey = GlobalKey();

  Future<ShareResult?> capturePng() async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/gameverse_score_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      return ShareResult(pngBytes: pngBytes, filePath: file.path);
    } catch (_) {
      return null;
    }
  }

  static void showSavedToast(BuildContext context) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => _ShareSavedToast(
        onDismiss: () => entry?.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _ShareSavedToast extends StatefulWidget {
  final VoidCallback onDismiss;
  const _ShareSavedToast({required this.onDismiss});

  @override
  State<_ShareSavedToast> createState() => _ShareSavedToastState();
}

class _ShareSavedToastState extends State<_ShareSavedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Positioned.fill(
        child: IgnorePointer(
          child: Opacity(
            opacity: _fade.value,
            child: Container(
              color: Colors.black.withValues(alpha: 0.4 * _fade.value),
              child: Center(
                child: Transform.scale(
                  scale: _scale.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F0F23), Color(0xFF1A0A2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            ),
                          ),
                          child: const Icon(Icons.check, color: Colors.black87, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Score Card Saved!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your card is ready to share',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.5),
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
