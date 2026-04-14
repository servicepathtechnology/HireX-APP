import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';

class LiveChallengeRoomPage extends ConsumerWidget {
  const LiveChallengeRoomPage({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveRoomProvider(matchId));

    // Navigate to result when match completes (timer hits 0 or both submitted)
    ref.listen(liveRoomProvider(matchId), (prev, next) {
      if (next.remainingSeconds == 0 && prev?.remainingSeconds != 0) {
        // Give evaluation a moment to process, then navigate
        Future.delayed(const Duration(seconds: 3), () {
          if (context.mounted) {
            context.go('/challenges/1v1/$matchId/result');
          }
        });
      }
    });

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: HireXLoader()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(state.error!, style: const TextStyle(color: AppColors.error)),
        ),
      );
    }

    final match = state.match!;

    return PopScope(
      canPop: false,
      child: _AntiCheatWrapper(
        matchId: matchId,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(state: state, match: match, matchId: matchId),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel: Task brief (40%)
                      Expanded(
                        flex: 4,
                        child: _TaskBriefPanel(match: match),
                      ),
                      Container(width: 1, color: AppColors.divider),
                      // Right panel: Submission (60%)
                      Expanded(
                        flex: 6,
                        child: _SubmissionPanel(
                          state: state,
                          match: match,
                          matchId: matchId,
                        ),
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
  }
}

// ── Anti-Cheat Wrapper ────────────────────────────────────────────────────────

/// Detects app backgrounding (tab switch equivalent on mobile) and logs it.
/// Also intercepts clipboard paste events via the code editor.
class _AntiCheatWrapper extends StatefulWidget {
  const _AntiCheatWrapper({required this.matchId, required this.child});
  final String matchId;
  final Widget child;

  @override
  State<_AntiCheatWrapper> createState() => _AntiCheatWrapperState();
}

class _AntiCheatWrapperState extends State<_AntiCheatWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background — log as tab switch
      AnalyticsService.instance.antiCheatEvent(widget.matchId, 'app_backgrounded');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.state, required this.match, required this.matchId});
  final LiveRoomState state;
  final MatchEntity match;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Domain badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              match.domain.label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Opponent status
          _OpponentStatusIndicator(status: state.opponentStatus),

          const Spacer(),

          // Spectator count
          if ((state.spectatorCount) > 0) ...[
            Icon(Icons.visibility_rounded, size: 14, color: AppColors.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              '${state.spectatorCount}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurface.withValues(alpha: 0.6),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Connection indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.isConnected ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Timer
          _CountdownTimer(
            seconds: state.remainingSeconds,
            isCritical: state.isTimerCritical,
          ),

          const SizedBox(width: 12),

          // Submit button
          if (!state.hasSubmitted)
            ElevatedButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => ref.read(liveRoomProvider(matchId).notifier).showConfirmDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Submitted',
                    style: TextStyle(
                      color: AppColors.success,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

class _CountdownTimer extends StatelessWidget {
  const _CountdownTimer({required this.seconds, required this.isCritical});
  final int seconds;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final text = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCritical
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCritical ? AppColors.error : AppColors.divider,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isCritical ? AppColors.error : Colors.white,
          fontFamily: 'Inter',
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _OpponentStatusIndicator extends StatelessWidget {
  const _OpponentStatusIndicator({required this.status});
  final OpponentStatus status;

  Color get _color {
    switch (status) {
      case OpponentStatus.waiting: return AppColors.onSurface;
      case OpponentStatus.working: return AppColors.warning;
      case OpponentStatus.submitted: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          'Opponent: ${status.label}',
          style: TextStyle(
            fontSize: 12,
            color: _color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

// ── Task Brief Panel ──────────────────────────────────────────────────────────

class _TaskBriefPanel extends StatelessWidget {
  const _TaskBriefPanel({required this.match});
  final MatchEntity match;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.taskTitle ?? 'Challenge Task',
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 16),
          if (match.taskDescription != null) ...[
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.taskDescription!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (match.taskRequirements != null) ...[
            const Text(
              'Requirements',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match.taskRequirements!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                fontFamily: 'Inter',
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Evaluation Criteria',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          ...['Clarity', 'Depth', 'Relevance', 'Quality of Execution'].map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '$c — 0–25 pts',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurface,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submission Panel ──────────────────────────────────────────────────────────

class _SubmissionPanel extends ConsumerWidget {
  const _SubmissionPanel({
    required this.state,
    required this.match,
    required this.matchId,
  });

  final LiveRoomState state;
  final MatchEntity match;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(liveRoomProvider(matchId).notifier);

    return Stack(
      children: [
        Column(
          children: [
            if (match.domain == ChallengeDomain.coding)
              _LanguageSelector(
                selected: state.selectedLanguage,
                onChanged: notifier.setLanguage,
              ),
            Expanded(
              child: _buildEditor(context, ref, notifier),
            ),
          ],
        ),
        // Submit confirm dialog
        if (state.showSubmitConfirm)
          _SubmitConfirmOverlay(
            onConfirm: () => notifier.submit(),
            onCancel: notifier.hideConfirmDialog,
          ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context, WidgetRef ref, LiveRoomNotifier notifier) {
    // 1v1 is coding-only — always show the code editor
    return _CodeEditor(
      content: state.submissionContent,
      onChanged: notifier.updateContent,
      readOnly: state.hasSubmitted,
      matchId: matchId,
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  static const _langs = ['python', 'javascript', 'java', 'cpp', 'go', 'rust', 'sql'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: _langs.map((lang) {
          final isSelected = selected == lang;
          return GestureDetector(
            onTap: () => onChanged(lang),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lang,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                  fontFamily: 'Inter',
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CodeEditor extends StatefulWidget {
  const _CodeEditor({
    required this.content,
    required this.onChanged,
    required this.readOnly,
    this.matchId,
  });
  final String content;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  final String? matchId;

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onPaste() {
    // Log clipboard paste as anti-cheat event (not penalized, just flagged)
    if (widget.matchId != null) {
      AnalyticsService.instance.antiCheatEvent(widget.matchId!, 'clipboard_paste');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): _onPaste,
          const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _onPaste,
        },
        child: TextField(
          controller: _ctrl,
          readOnly: widget.readOnly,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFFE6EDF3),
            height: 1.6,
          ),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: '// Write your solution here...',
            hintStyle: TextStyle(
              color: Color(0xFF6E7681),
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class _RichTextEditor extends StatefulWidget {
  const _RichTextEditor({
    required this.content,
    required this.onChanged,
    required this.readOnly,
    required this.domain,
  });
  final String content;
  final ValueChanged<String> onChanged;
  final bool readOnly;
  final ChallengeDomain domain;

  @override
  State<_RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<_RichTextEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _placeholder => 'Write your response here...';

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      readOnly: widget.readOnly,
      maxLines: null,
      expands: true,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: Colors.white,
        height: 1.7,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(16),
        border: InputBorder.none,
        hintText: _placeholder,
        hintStyle: const TextStyle(
          color: AppColors.onSurface,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _DesignSubmission extends StatefulWidget {
  const _DesignSubmission({
    required this.content,
    required this.onChanged,
    required this.readOnly,
  });
  final String content;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  @override
  State<_DesignSubmission> createState() => _DesignSubmissionState();
}

class _DesignSubmissionState extends State<_DesignSubmission> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Figma Link or Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            readOnly: widget.readOnly,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
            decoration: const InputDecoration(
              hintText: 'Paste Figma link or describe your design...',
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

class _SubmitConfirmOverlay extends StatelessWidget {
  const _SubmitConfirmOverlay({required this.onConfirm, required this.onCancel});
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Submit your answer?',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You cannot edit your submission after confirming.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        foregroundColor: AppColors.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontFamily: 'Inter')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
