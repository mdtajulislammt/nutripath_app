import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/app_state_provider.dart';
import '../../models/chat_message.dart';
import '../../models/meal_slot.dart';
import '../../services/bengali_ai_nutritionist.dart';
import '../../services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isThinking = false;

  final List<String> _initialQuickQuestions = [
    '১ প্লেট ভাতে কত ক্যালোরি?',
    'আজকে রাতে কি খাওয়া ভালো?',
    'ওজন কমানোর সহজ উপায় কি?',
    'আমার আজকের ক্যালোরি বাজেট কত?',
    'ডিমের পুষ্টিগুণ ও ক্যালোরি কত?',
    'গ্যাস্ট্রিকের জন্য কি খাব?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistoryFromBackend();
  }

  Future<void> _loadHistoryFromBackend() async {
    try {
      final history = await ApiService.instance.getAiChatHistory();
      if (mounted && history != null && history.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (var item in history) {
            _messages.add(
              ChatMessage(
                id: item['id'] ?? '',
                text: item['content'] ?? '',
                isUser: item['role'] == 'user',
                timestamp: DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
                quickFollowUps: (item['quickFollowUps'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
              ),
            );
          }
        });
        _scrollToBottom();
        return;
      }
    } catch (_) {}

    if (mounted && _messages.isEmpty) {
      _loadInitialWelcome();
    }
  }

  void _loadInitialWelcome() {
    final state = context.read<AppStateProvider>();
    final profile = state.profile;
    final metrics = state.metrics;
    final name = profile.name.isNotEmpty ? profile.name : 'বন্ধু';
    final isGain = metrics.isWeightGain;
    final isLoss = metrics.isWeightLoss;
    final diffKg = (profile.targetWeight - profile.weight).abs();

    final goalBadge = isGain
        ? '💪 ওজন বৃদ্ধি (Weight Gain): +${diffKg.toStringAsFixed(1)} কেজি'
        : (isLoss
            ? '🔥 ওজন কমানো (Weight Loss): -${diffKg.toStringAsFixed(1)} কেজি'
            : '⚖️ ওজন বজায় রাখা (Maintenance)');

    _messages.add(
      ChatMessage(
        id: 'welcome',
        text: 'আসসালামু আলাইকুম $name! 👋\n\n'
            'আমি আপনার ব্যক্তিগত **AI পুষ্টি ও ডায়েট বিশেষজ্ঞ**। আপনার ৪-স্টেপ সেটআপের তথ্য পড়ে নিয়েছি:\n\n'
            '• **আপনার লক্ষ্য:** $goalBadge\n'
            '• **দৈনিক প্রস্তাবিত বাজেট:** **${metrics.budget} kcal** (BMR: ${metrics.bmr} kcal, TDEE: ${metrics.tdee} kcal)\n'
            '• **পানি পানের লক্ষ্য:** ${metrics.waterGoalGlasses} গ্লাস (${metrics.waterGoalLiters}L)\n'
            '• **ব্যায়াম/শরীরচর্চা:** ${metrics.walkMinGoal} মিনিট\n'
            '• **স্বাস্থ্য সতর্কতা:** ${profile.conditions.isEmpty ? "কোনো জটিলতা নেই" : profile.conditions.join(", ")}\n\n'
            'আজকে আপনার কোন বেলা কতটুকু ক্যালোরি খাওয়া উচিত, কি কি খাবার খাবেন বা যেকোনো দেশি খাবারের পুষ্টি সম্পর্কে বাংলায় প্রশ্ন করুন:',
        isUser: false,
        timestamp: DateTime.now(),
        quickFollowUps: [
          'আমার দৈনিক কত ক্যালোরি খাওয়া উচিত?',
          'আজকে কোন বেলা কি কি খাবার খাব?',
          isGain ? 'ওজন বাড়ানোর সহজ উপায় কি?' : 'ওজন কমানোর সহজ উপায় কি?',
          'আমার আজকের ক্যালোরি স্ট্যাটাস কি?',
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty || _isThinking) return;

    if (presetText == null) {
      _inputController.clear();
    }

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _scrollToBottom();

    final state = context.read<AppStateProvider>();
    ChatMessage aiReply;

    final userContext = {
      'name': state.profile.name,
      'age': state.profile.age,
      'gender': state.profile.gender.name,
      'currentWeight': state.profile.weight,
      'targetWeight': state.profile.targetWeight,
      'targetMonths': state.profile.months,
      'goalType': state.metrics.goalType.name,
      'dailyKcalBudget': state.metrics.budget,
      'bmr': state.metrics.bmr,
      'tdee': state.metrics.tdee,
      'waterGoalGlasses': state.metrics.waterGoalGlasses,
      'waterGoalLiters': state.metrics.waterGoalLiters,
      'walkMinGoal': state.metrics.walkMinGoal,
      'conditions': state.profile.conditions,
      'consumedKcal': state.consumedKcal,
      'remainingKcal': (state.metrics.budget - state.consumedKcal).clamp(0, state.metrics.budget),
      'isOverBudget': state.isOverBudget,
      'excessKcal': state.excessKcal,
      'waterGlasses': state.waterGlasses,
      'walkMinutes': state.walkMinutes,
      'slotBudgets': {
        for (var s in MealSlot.values) s.name: state.slotBudget(s),
      },
      'todayMeals': {
        for (var s in MealSlot.values)
          s.name: (state.meals[s] ?? [])
              .map((i) => {'name': i.name, 'qty': i.qty, 'kcal': i.kcal})
              .toList(),
      },
    };

    // 1. Try Backend Gemini AI Service with rich user context
    try {
      final res = await ApiService.instance.queryAiChat(text, userContext: userContext);
      if (res != null && res['assistantMessage'] != null) {
        final a = res['assistantMessage'];
        final followUps = (a['quickFollowUps'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        aiReply = ChatMessage(
          id: a['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: a['content'] ?? '',
          isUser: false,
          timestamp: DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now(),
          quickFollowUps: followUps,
        );
      } else {
        throw Exception('Server returned empty response');
      }
    } catch (_) {
      // 2. Fallback to rich personalized BengaliAiNutritionist reading all user info
      aiReply = await BengaliAiNutritionist.generateResponse(
        query: text,
        profile: state.profile,
        metrics: state.metrics,
        aiPlan: state.aiPlan,
        consumedKcal: state.consumedKcal,
        remainingKcal: (state.metrics.budget - state.consumedKcal).clamp(0, state.metrics.budget),
        daysOnDiet: state.totalDaysOnDiet,
        waterGlasses: state.waterGlasses,
        walkMinutes: state.walkMinutes,
        todayMeals: state.meals,
      );
    }

    if (mounted) {
      setState(() {
        _isThinking = false;
        _messages.add(aiReply);
      });
      _scrollToBottom();
    }
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('চ্যাট হিস্ট্রি মুছবেন?'),
        content: const Text('আপনার বর্তমান কথোপকথনগুলো মুছে নতুন চ্যাট শুরু করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('না'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _loadInitialWelcome();
              });
              try {
                await ApiService.instance.clearAiChatHistory();
              } catch (_) {}
            },
            child: const Text('মুছে ফেলুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textDark = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.slate400 : const Color(0xFF64748B);
    final cardBg = isDark ? AppColors.slate800 : Colors.white;
    final borderColor = isDark ? AppColors.slate700 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.slate900 : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0.5,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI পুষ্টিবিদ',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'সক্রিয় ও প্রস্তুত',
                      style: TextStyle(
                        fontSize: 11,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 19, color: textMuted),
            tooltip: 'চ্যাট ক্লিয়ার করুন',
            onPressed: _confirmClearChat,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildThinkingBubble(isDark, cardBg, borderColor, textMuted);
                  }

                  final msg = _messages[index];
                  return _buildMessageBubble(
                    msg: msg,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textDark: textDark,
                    textMuted: textMuted,
                  );
                },
              ),
            ),

            // Quick Questions Slider (shown when fewer messages)
            if (_messages.length <= 3) ...[
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _initialQuickQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final q = _initialQuickQuestions[index];
                    return InkWell(
                      onTap: () => _handleSend(q),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate800 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          q,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.slate300 : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.slate900 : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: TextStyle(fontSize: 14, color: textDark),
                        decoration: InputDecoration(
                          hintText: 'খাবারের ক্যালোরি বা ডায়েট নিয়ে বাংলায় প্রশ্ন করুন...',
                          hintStyle: TextStyle(fontSize: 13, color: textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: _inputController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _inputController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (text) => _handleSend(text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _inputController.text.trim().isEmpty || _isThinking
                        ? null
                        : () => _handleSend(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _inputController.text.trim().isEmpty || _isThinking
                            ? (isDark ? AppColors.slate800 : const Color(0xFFE2E8F0))
                            : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: _inputController.text.trim().isEmpty || _isThinking
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.sendHorizontal,
                          size: 19,
                          color: _inputController.text.trim().isEmpty || _isThinking
                              ? textMuted
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage msg,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textDark,
    required Color textMuted,
  }) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(msg.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE7F7F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.sparkles,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(color: borderColor, width: 1.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormattedMarkdownText(text: msg.text, textDark: textDark),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('h:mm a').format(msg.timestamp),
                              style: TextStyle(fontSize: 10.5, color: textMuted),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: msg.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('টেক্সট কপি করা হয়েছে!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(LucideIcons.copy, size: 14, color: textMuted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Follow Up Chips
                  if (msg.quickFollowUps != null && msg.quickFollowUps!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.quickFollowUps!.map((fu) {
                        return InkWell(
                          onTap: () => _handleSend(fu),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFE7F7F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.cornerDownRight,
                                  size: 11,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  fu,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildThinkingBubble(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFE7F7F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.sparkles,
                color: Color(0xFF10B981),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'পুষ্টিবিদ ভাবছে...',
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple parser to nicely style bold text (`**text**`) and bullet points in Bengali
class _FormattedMarkdownText extends StatelessWidget {
  final String text;
  final Color textDark;

  const _FormattedMarkdownText({required this.text, required this.textDark});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return const SizedBox(height: 6);
        }

        final spans = <TextSpan>[];
        final parts = line.split('**');

        for (int i = 0; i < parts.length; i++) {
          final isBold = i % 2 == 1;
          spans.add(
            TextSpan(
              text: parts[i],
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
                color: textDark,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: RichText(text: TextSpan(children: spans)),
        );
      }).toList(),
    );
  }
}
