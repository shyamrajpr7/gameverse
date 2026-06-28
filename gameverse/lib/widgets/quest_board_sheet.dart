import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/haptic_service.dart';

class QuestBoardSheet extends StatefulWidget {
  const QuestBoardSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QuestBoardSheet(),
    );
  }

  @override
  State<QuestBoardSheet> createState() => _QuestBoardSheetState();
}

class _QuestBoardSheetState extends State<QuestBoardSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _claimReward(Quest quest) async {
    final claimed = await GameService().claimQuestReward(quest.id);
    if (claimed != null && mounted) {
      AudioService().play(SoundType.achievement);
      HapticService.medium();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Claimed +${quest.xpReward} XP and +${quest.coinReward} Coins!',
            ),
            backgroundColor: const Color(0xFF1E1E40),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F23),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildTabs(),
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestList(QuestType.daily),
                _buildQuestList(QuestType.weekly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFFFD700),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 22),
            const SizedBox(width: 10),
            const Text(
              'QUEST BOARD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFFFD700),
        indicatorWeight: 3,
        labelColor: const Color(0xFFFFD700),
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
        ],
      ),
    );
  }

  Widget _buildQuestList(QuestType type) {
    final quests = GameService()
        .activeQuests
        .where((q) => q.type == type)
        .toList();

    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              'All caught up! Check back later.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: quests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _QuestCard(
          quest: quests[index],
          onClaim: _claimReward,
        );
      },
    );
  }
}

class _QuestCard extends StatefulWidget {
  final Quest quest;
  final Future<void> Function(Quest quest) onClaim;

  const _QuestCard({
    required this.quest,
    required this.onClaim,
  });

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.quest.isCompleted && !widget.quest.isClaimed) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_QuestCard old) {
    super.didUpdateWidget(old);
    if (widget.quest.isCompleted && !widget.quest.isClaimed) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData _targetIcon(QuestTargetType type) {
    switch (type) {
      case QuestTargetType.playGames:
        return Icons.play_arrow_rounded;
      case QuestTargetType.reachScore:
        return Icons.emoji_events;
      case QuestTargetType.earnCoins:
      case QuestTargetType.spendCoins:
        return Icons.monetization_on;
      case QuestTargetType.levelUp:
        return Icons.arrow_upward;
    }
  }

  Color _targetColor(QuestTargetType type) {
    switch (type) {
      case QuestTargetType.playGames:
        return const Color(0xFF4FC3F7);
      case QuestTargetType.reachScore:
        return const Color(0xFFFFD700);
      case QuestTargetType.earnCoins:
        return const Color(0xFF00B894);
      case QuestTargetType.spendCoins:
        return const Color(0xFFFF6B6B);
      case QuestTargetType.levelUp:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final progress = quest.progress;
    final color = _targetColor(quest.targetType);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            const Color(0xFF0F0F23),
          ],
        ),
        border: Border.all(
          color: quest.isClaimed
              ? const Color(0xFF00B894).withValues(alpha: 0.25)
              : const Color(0xFFFFD700).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(color),
                const SizedBox(width: 12),
                Expanded(child: _buildInfo(quest)),
                const SizedBox(width: 8),
                _buildAction(quest),
              ],
            ),
            const SizedBox(height: 10),
            _buildProgressBar(progress, quest, color),
            const SizedBox(height: 8),
            _buildRewards(quest),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.15),
      ),
      child: Icon(
        _targetIcon(widget.quest.targetType),
        size: 22,
        color: color,
      ),
    );
  }

  Widget _buildInfo(Quest quest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          quest.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          quest.description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        if (quest.isClaimed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 13,
                  color: const Color(0xFF00B894).withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Claimed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00B894).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAction(Quest quest) {
    if (quest.isClaimed) {
      return Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF00B894).withValues(alpha: 0.12),
          border: Border.all(
            color: const Color(0xFF00B894).withValues(alpha: 0.2),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            color: Color(0xFF00B894),
            size: 18,
          ),
        ),
      );
    }

    if (quest.isCompleted) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) {
          return Transform.scale(
            scale: _pulseAnim.value,
            child: GestureDetector(
              onTap: () => widget.onClaim(quest),
              child: Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Claim',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: 60,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: widget.quest.progress,
            color: _targetColor(widget.quest.targetType),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, Quest quest, Color color) {
    final barColor = quest.isClaimed
        ? const Color(0xFF00B894)
        : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${quest.currentValue} / ${quest.targetValue}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRewards(Quest quest) {
    return Row(
      children: [
        _rewardChip(
          '+${quest.xpReward} XP',
          const Color(0xFF4FC3F7),
        ),
        const SizedBox(width: 8),
        _rewardChip(
          '+${quest.coinReward} Coins',
          const Color(0xFFFFD700),
        ),
      ],
    );
  }

  Widget _rewardChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
