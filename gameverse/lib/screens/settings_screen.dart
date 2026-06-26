import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundMuted = AudioService().isMuted;
  bool _hapticsEnabled = HapticService().isHapticsEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Preferences', Icons.tune),
                  const SizedBox(height: 12),
                  _buildToggleTile(
                    icon: Icons.volume_up,
                    title: 'Sound Effects',
                    subtitle: 'Enable or disable game sounds',
                    value: !_soundMuted,
                    onChanged: (v) {
                      setState(() => _soundMuted = !v);
                      AudioService().toggleMute();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildToggleTile(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibration on interactions',
                    value: _hapticsEnabled,
                    onChanged: (v) {
                      setState(() => _hapticsEnabled = v);
                      HapticService().setHapticsEnabled(v);
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('About', Icons.info_outline),
                  const SizedBox(height: 12),
                  _buildAboutSection(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Data', Icons.delete_outline),
                  const SizedBox(height: 12),
                  _buildResetButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 40,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A1A),
      leading: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: const FlexibleSpaceBar(
        background: Padding(
          padding: EdgeInsets.only(top: 48, left: 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Customize your experience', style: TextStyle(fontSize: 13, color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFFD700)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFFFFD700), size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        value: value,
        activeThumbColor: const Color(0xFFFFD700),
        activeTrackColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
        inactiveThumbColor: Colors.white38,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                ),
                child: const Center(
                  child: Text('GV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GameVerse', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Colors.white38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'GameVerse is a collection of 12 retro and modern arcade mini-games. '
            'Play games, earn XP, unlock badges, and compete for high scores.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 12, color: Color(0xFF6C5CE7)),
                SizedBox(width: 6),
                Text('Built with Flutter', style: TextStyle(fontSize: 11, color: Color(0xFF6C5CE7), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: TextButton.icon(
        onPressed: _confirmReset,
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 20),
        label: const Text(
          'Reset Progress',
          style: TextStyle(
            color: Color(0xFFFF6B6B),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 24),
            SizedBox(width: 10),
            Text('Reset Progress', style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
        content: Text(
          'This will erase all your XP, badges, high scores, and game history. '
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final gs = GameService();
      await gs.load();
      if (mounted) {
        setState(() {
          _soundMuted = AudioService().isMuted;
          _hapticsEnabled = HapticService().isHapticsEnabled;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Progress has been reset'),
            backgroundColor: const Color(0xFF6C5CE7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}
