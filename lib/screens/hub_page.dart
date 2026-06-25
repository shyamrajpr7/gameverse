import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gamification_service.dart';
import 'flappy_bird_page.dart';
import 'snake_game_page.dart';

const Color _cardBg = Color(0xFF1E293B);
const Color _violet = Color(0xFF8B5CF6);
const Color _emerald = Color(0xFF10B981);
const Color _cyan = Color(0xFF06B6D4);
const Color _amber = Color(0xFFF59E0B);
const Color _red = Color(0xFFEF4444);
const Color _rose = Color(0xFFF43F5E);
const Color _slateText = Color(0xFF94A3B8);
const Color _whiteText = Color(0xFFF1F5F9);
const Color _bgCanvas = Color(0xFF0F172A);

const List<Color> accentColors = [
  _violet,
  _emerald,
  _cyan,
  _amber,
  _red,
  _rose,
  Color(0xFF3B82F6),
  Color(0xFFF97316),
];

class AppDocument {
  final String id;
  String title;
  String content;
  final String type;
  String? filePath;
  final DateTime createdAt;

  AppDocument({
    required this.id,
    required this.title,
    this.content = '',
    required this.type,
    this.filePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type,
        'filePath': filePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppDocument.fromJson(Map<String, dynamic> json) => AppDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ?? '',
        type: json['type'] as String? ?? 'note',
        filePath: json['filePath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }

  int get sizeBytes => content.length;
}

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  final _gamification = GamificationService();

  String _username = 'User';
  Color _accentColor = _violet;
  List<AppDocument> _documents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _gamification.load(),
      _loadProfile(),
      _loadDocuments(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('hub_username') ?? 'User';
      final colorVal = prefs.getInt('hub_accent_color');
      if (colorVal != null) {
        _accentColor = Color.fromARGB(
          (colorVal >> 24) & 0xFF,
          (colorVal >> 16) & 0xFF,
          (colorVal >> 8) & 0xFF,
          colorVal & 0xFF,
        );
      }
    });
  }

  Future<void> _saveUsername(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hub_username', name);
    setState(() => _username = name);
  }

  Future<void> _saveAccentColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hub_accent_color', color.toARGB32());
    setState(() => _accentColor = color);
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('hub_documents');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data) as List<dynamic>;
      setState(() {
        _documents = list
            .map((j) => AppDocument.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      });
    }
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_documents.map((d) => d.toJson()).toList());
    await prefs.setString('hub_documents', data);
  }

  // ─── Profile ───

  void _showEditProfileDialog() {
    final controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile',
            style: TextStyle(color: _whiteText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: _whiteText),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: const TextStyle(color: _slateText),
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: _slateText.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _violet, width: 2),
                ),
                filled: true,
                fillColor: _bgCanvas,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Accent Color',
                style: TextStyle(color: _slateText, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: accentColors.map((c) {
                final selected = c.toARGB32() == _accentColor.toARGB32();
                return GestureDetector(
                  onTap: () => _saveAccentColor(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _slateText)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _saveUsername(text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─── Documents ───

  void _showNewNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Note',
            style: TextStyle(color: _whiteText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: _whiteText),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: _slateText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _violet, width: 2),
                ),
                filled: true,
                fillColor: _bgCanvas,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              style: const TextStyle(color: _whiteText),
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: const TextStyle(color: _slateText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _slateText.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _violet, width: 2),
                ),
                filled: true,
                fillColor: _bgCanvas,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: _slateText)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isNotEmpty) {
                _addDocument(AppDocument(
                  id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
                  title: title,
                  content: content,
                  type: 'note',
                  createdAt: DateTime.now(),
                ));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final dir = await getApplicationDocumentsDirectory();
    final savedPath = '${dir.path}/${file.name}';
    if (file.path != null) {
      await File(file.path!).copy(savedPath);
    }
    _addDocument(AppDocument(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
      title: file.name,
      content: file.name,
      type: 'file',
      filePath: savedPath,
      createdAt: DateTime.now(),
    ));
  }

  void _addDocument(AppDocument doc) {
    setState(() => _documents.insert(0, doc));
    _saveDocuments();
  }

  Future<void> _deleteDocument(AppDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Note', style: TextStyle(color: _whiteText, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this note?', style: TextStyle(color: _slateText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _slateText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: _rose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _documents.removeWhere((d) => d.id == doc.id));
    _saveDocuments();
    if (doc.filePath != null) {
      File(doc.filePath!).delete().ignore();
    }
  }

  Future<void> _shareDocument(AppDocument doc) async {
    if (doc.type == 'file' && doc.filePath != null) {
      final file = XFile(doc.filePath!);
      await Share.shareXFiles([file], text: doc.title);
    } else {
      await Share.share(
        '${doc.title}\n\n${doc.content}',
        subject: doc.title,
      );
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _slateText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add to Vault',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _whiteText)),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.note_add_rounded, color: _violet),
              ),
              title: const Text('New Note', style: TextStyle(color: _whiteText, fontWeight: FontWeight.w600)),
              subtitle: const Text('Write a text note', style: TextStyle(color: _slateText, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showNewNoteDialog();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.attach_file_rounded, color: _cyan),
              ),
              title: const Text('Import File', style: TextStyle(color: _whiteText, fontWeight: FontWeight.w600)),
              subtitle: const Text('Pick a file from your device', style: TextStyle(color: _slateText, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _violet));
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildAchievementsCard(),
              const SizedBox(height: 24),
              _buildMiniGamesCard(),
              const SizedBox(height: 24),
              _buildVaultHeader(),
              const SizedBox(height: 12),
              _buildDocumentList(),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton(
          onPressed: _showAddOptions,
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, size: 28),
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
            color: _accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.widgets_rounded, color: _accentColor, size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          'Hub',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _whiteText,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final initial = _username.isNotEmpty ? _username[0].toUpperCase() : '?';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cardBg, _cardBg.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _accentColor.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _whiteText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Personal Hub',
                  style: TextStyle(fontSize: 12, color: _slateText),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showEditProfileDialog,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_rounded, size: 18, color: _accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    final xp = _gamification.currentXP;
    final level = GamificationService.getLevel(xp);
    final progress = GamificationService.getProgress(xp);
    final unlocked = _gamification.unlockedBadges;
    final displayedBadges = allBadges.take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, size: 16, color: _amber),
              const SizedBox(width: 8),
              const Text('Achievements & Stats',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _whiteText)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.stars_rounded,
                  value: '$xp',
                  label: 'XP',
                  color: _amber,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.military_tech_rounded,
                  value: '$level',
                  label: 'Level',
                  color: _violet,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.checklist_rounded,
                  value: '${_gamification.tasksCompleted}',
                  label: 'Tasks',
                  color: _emerald,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.timer_rounded,
                  value: '${_gamification.focusSessionsCompleted}',
                  label: 'Focus',
                  color: _cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _slateText.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(_violet),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: displayedBadges.map((b) {
              final has = b.isUnlocked(unlocked);
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: has ? _amber.withValues(alpha: 0.1) : _slateText.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: has
                        ? _amber.withValues(alpha: 0.2)
                        : _slateText.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  b.icon,
                  size: 18,
                  color: has ? _amber : _slateText.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGamesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_esports_rounded, size: 16, color: _violet),
            ),
            const SizedBox(width: 10),
            const Text('Mini-Games',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _whiteText)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildGameCard(
                title: 'Flappy Bird',
                subtitle: 'Tap to fly & earn XP',
                icon: Icons.videogame_asset_rounded,
                color: _amber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FlappyBirdPage())),
              ),
              const SizedBox(width: 12),
              _buildGameCard(
                title: 'Neon Snake',
                subtitle: 'Classic snake with a neon twist',
                icon: Icons.gesture_rounded,
                color: _cyan,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SnakeGamePage())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, color: color.withValues(alpha: 0.5), size: 14),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _whiteText),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: _slateText.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_rounded, size: 16, color: _cyan),
        ),
        const SizedBox(width: 10),
        const Text('Documents Vault',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _whiteText)),
        const Spacer(),
        Text(
          '${_documents.length} item${_documents.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: _slateText),
        ),
      ],
    );
  }

  Widget _buildDocumentList() {
    if (_documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _slateText.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded, size: 36, color: _slateText.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text('Your vault is empty',
                style: TextStyle(fontSize: 14, color: _slateText.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('Tap + to add notes or files',
                style: TextStyle(fontSize: 12, color: _slateText.withValues(alpha: 0.3))),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _documents.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _DocumentCard(
        document: _documents[i],
        accentColor: _accentColor,
        onDelete: () => _deleteDocument(_documents[i]),
        onShare: () => _shareDocument(_documents[i]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _whiteText,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: _slateText.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final AppDocument document;
  final Color accentColor;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _DocumentCard({
    required this.document,
    required this.accentColor,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isFile = document.type == 'file';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slateText.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isFile ? _cyan : _violet).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFile ? Icons.insert_drive_file_rounded : Icons.article_rounded,
              size: 20,
              color: isFile ? _cyan : _violet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _whiteText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      document.formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: _slateText.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFile ? 'File' : '${document.sizeBytes}B',
                      style: TextStyle(
                        fontSize: 11,
                        color: _slateText.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onShare,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.share_rounded, size: 16, color: accentColor),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _rose.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 16, color: _rose.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
