import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

const Color _cardBg = Color(0xFF1E293B);
const Color _violet = Color(0xFF8B5CF6);
const Color _emerald = Color(0xFF10B981);
const Color _cyan = Color(0xFF06B6D4);
const Color _amber = Color(0xFFF59E0B);
const Color _slateText = Color(0xFF94A3B8);
const Color _whiteText = Color(0xFFF1F5F9);

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _gamification = GamificationService();

  @override
  void initState() {
    super.initState();
    _gamification.load().then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final xp = _gamification.currentXP;
    final level = GamificationService.getLevel(xp);
    final progress = GamificationService.getProgress(xp);
    final nextXp = GamificationService.xpForLevel(level + 1);
    final currentLevelXp = GamificationService.xpForLevel(level);
    final unlockedCount = _gamification.unlockedBadges.length;
    final totalCount = allBadges.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildLevelCard(level, xp, progress, currentLevelXp, nextXp),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionHeader('Badges', '$unlockedCount / $totalCount'),
            const SizedBox(height: 12),
            _buildBadgeGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.emoji_events_rounded, color: _amber, size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _whiteText,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard(int level, int xp, double progress, int current, int next) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_violet.withValues(alpha: 0.2), _violet.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _violet.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $level',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _whiteText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$xp / $next XP',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _slateText,
                    ),
                  ),
                ],
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_violet, _violet.withValues(alpha: 0.6)],
                  ),
                ),
                child: Center(
                  child: Text(
                    '$level',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: _slateText.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(_violet),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${xp - current} / ${next - current} XP to next level',
              style: TextStyle(
                fontSize: 11,
                color: _slateText.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.checklist_rounded,
          value: '${_gamification.tasksCompleted}',
          label: 'Tasks Done',
          color: _emerald,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.timer_rounded,
          value: '${_gamification.focusSessionsCompleted}',
          label: 'Focus Sessions',
          color: _cyan,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.emoji_events_rounded,
          value: '$unlockedCount',
          label: 'Badges',
          color: _amber,
        )),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _whiteText,
          ),
        ),
        const Spacer(),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: _slateText,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: allBadges.length,
      itemBuilder: (_, i) => _BadgeCard(
        badge: allBadges[i],
        unlocked: allBadges[i].isUnlocked(_gamification.unlockedBadges),
      ),
    );
  }

  int get unlockedCount => _gamification.unlockedBadges.length;
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _whiteText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _slateText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementBadge badge;
  final bool unlocked;

  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? _cardBg : _cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? _violet.withValues(alpha: 0.2)
              : _slateText.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.icon,
            size: 28,
            color: unlocked ? _amber : _slateText.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: unlocked ? _whiteText : _slateText.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unlocked ? 'Unlocked' : '???',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: unlocked
                  ? _emerald.withValues(alpha: 0.7)
                  : _slateText.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
