import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/game_colors.dart';
import '../widgets/ui_kit.dart';

/// A single help article.
class _Faq {
  const _Faq(this.category, this.question, this.answer);
  final String category;
  final String question;
  final String answer;
}

const String kSupportEmail = 'support@arrowspro.game';

const List<_Faq> _faqs = [
  _Faq(
    'GETTING STARTED',
    'How do I save my progress?',
    'Your progress saves automatically on this device after every level. '
        'Sign-in based cloud sync is on the way — for now, keep the game '
        'installed to keep your levels, coins and stars.',
  ),
  _Faq(
    'PIGGY BANK',
    'How does the Piggy Bank work?',
    'You earn coins into the Piggy Bank as you clear levels. Once it reaches '
        'the minimum, you can break it to move every saved coin into your '
        'spendable balance at once.',
  ),
  _Faq(
    'MY ACCOUNT & PROGRESS',
    'Can I play on two phones at the same time?',
    'Progress is stored per device right now, so two phones keep separate '
        'progress. Cloud accounts that sync across devices are planned.',
  ),
  _Faq(
    'HOW TO PLAY',
    'What are stars and why do they matter?',
    'Each level can be cleared for up to 3 stars. Stars add to your total, '
        'unlock new worlds, and show off how cleanly you solved a puzzle.',
  ),
  _Faq(
    'HOW TO PLAY',
    'How do lives work?',
    'You start with full lives. Failing a level costs one. Lives refill over '
        'time, or you can refill instantly with a free video, coins, or an '
        'infinite-lives bundle.',
  ),
  _Faq(
    'REMOVE ADS',
    'Does Remove Ads get rid of all ads?',
    'Remove Ads removes banner and full-screen ads. Optional reward videos '
        '(for free coins or lives) stay, so you can still earn bonuses.',
  ),
  _Faq(
    'AD ISSUES',
    'I cannot close an ad',
    'If an ad will not close, wait a few seconds for the close button to '
        'appear, then tap it. If it is still stuck, restart the app — your '
        'progress is safe.',
  ),
  _Faq(
    'PURCHASES',
    'How do I restore a purchase?',
    'Open Settings and tap RESTORE PURCHASE. The store re-delivers anything '
        'you have already bought (like Remove Ads) for free.',
  ),
];

/// A help-center style Support page: a hero with a search box, a filterable
/// list of expandable articles, and a contact footer.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _search = TextEditingController();
  String _query = '';
  int? _open;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Faq> get _filtered {
    if (_query.isEmpty) return _faqs;
    return _faqs
        .where((f) =>
            f.question.toLowerCase().contains(_query) ||
            f.answer.toLowerCase().contains(_query) ||
            f.category.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Scaffold(
      backgroundColor: GameColors.homeBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header bar ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  ChunkyCircleButton(
                    icon: Icons.arrow_back_rounded,
                    color: GameColors.blue,
                    size: 42,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text('Support',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  const _Hero(),
                  const SizedBox(height: 16),
                  // Search box.
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: TextField(
                      controller: _search,
                      style: const TextStyle(
                          color: GameColors.ink, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'Search for articles',
                        hintStyle: TextStyle(color: GameColors.inkMuted),
                        prefixIcon:
                            Icon(Icons.search_rounded, color: GameColors.inkMuted),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _query.isEmpty
                        ? 'POPULAR ARTICLES'
                        : '${results.length} RESULT${results.length == 1 ? '' : 'S'}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No articles match “${_search.text}”.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w700)),
                    ),
                  for (var i = 0; i < results.length; i++)
                    _ArticleCard(
                      faq: results[i],
                      open: _open == i,
                      onTap: () =>
                          setState(() => _open = _open == i ? null : i),
                    ),
                  const SizedBox(height: 18),
                  const _ContactFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The branded hero strip with a gently bobbing arrow mark.
class _Hero extends StatefulWidget {
  const _Hero();
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263456), Color(0xFF1B2540)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 + _c.value * 8),
              child: child,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 54),
          ),
          const SizedBox(height: 10),
          const Text('Hi, how can we help you?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// A white FAQ card that expands to reveal its answer with a smooth animation.
class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.faq,
    required this.open,
    required this.onTap,
  });
  final _Faq faq;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(faq.question,
                              style: const TextStyle(
                                  color: GameColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(faq.category,
                              style: const TextStyle(
                                  color: GameColors.inkMuted,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.chevron_right_rounded,
                          color: GameColors.inkMuted),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 6),
                    child: Text(faq.answer,
                        style: const TextStyle(
                            color: GameColors.ink,
                            height: 1.4,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                  crossFadeState: open
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactFooter extends StatelessWidget {
  const _ContactFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Need more help?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SizedBox(
          width: 220,
          child: ChunkyButton(
            color: GameColors.green,
            depth: 6,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 13),
            onTap: () => _showContact(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('CHAT WITH US',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showContact(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF3F5680),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.alternate_email_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  const Text('Email our team',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const SelectableText(kSupportEmail,
                      style: TextStyle(
                          color: Color(0xFFCFE0FF),
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          color: GameColors.blue,
                          depth: 5,
                          radius: 14,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          onTap: () {
                            Clipboard.setData(
                                const ClipboardData(text: kSupportEmail));
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('COPY',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChunkyButton(
                          color: const Color(0xFF566A8E),
                          depth: 5,
                          radius: 14,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          onTap: () => Navigator.of(ctx).pop(),
                          child: const Text('CLOSE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
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
