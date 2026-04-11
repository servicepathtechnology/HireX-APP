import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_avatar.dart';
import '../../../../shared/widgets/hirex_tag.dart';
import '../../../../shared/widgets/domain_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

class POWProfilePage extends ConsumerWidget {
  const POWProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(onPressed: () => dialogCtx.pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => dialogCtx.pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(powProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Profile', style: AppTextStyles.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => context.push('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ProfileError(
          error: e.toString(),
          onRetry: () => ref.invalidate(powProfileProvider),
          ref: ref,
        ),
        data: (data) => _ProfileBody(data: data),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final userData = data['user'] as Map<String, dynamic>? ?? {};
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final skillScore = data['skill_score'] as Map<String, dynamic>? ?? {};
    final badges = (data['badges'] as List<dynamic>?) ?? [];
    final recentSubs = (data['recent_submissions'] as List<dynamic>?) ?? [];

    return CustomScrollView(
      slivers: [
        // ── Hero header ───────────────────────────────────────────────────
        SliverToBoxAdapter(child: _HeroCard(userData: userData, profile: profile)),

        // ── Bio ───────────────────────────────────────────────────────────
        if ((profile['bio'] as String?)?.isNotEmpty == true)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _BioCard(bio: profile['bio'] as String),
            ),
          ),

        // ── Skills ────────────────────────────────────────────────────────
        if ((profile['skill_tags'] as List?)?.isNotEmpty == true)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SkillsCard(skills: (profile['skill_tags'] as List).cast<String>()),
            ),
          ),

        // ── Skill Score ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _SkillScoreCard(skillScore: skillScore),
          ),
        ),

        // ── Activity ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ActivitySection(stats: stats),
          ),
        ),

        // ── Badges ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _BadgesSection(badges: badges),
          ),
        ),

        // ── Task History ──────────────────────────────────────────────────
        if (recentSubs.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TaskHistorySection(submissions: recentSubs),
            ),
          ),

        // ── Public toggle ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: _PublicProfileToggle(isPublic: profile['public_profile'] as bool? ?? true),
          ),
        ),
      ],
    );
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.userData, required this.profile});
  final Map<String, dynamic> userData;
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final name = userData['full_name'] as String? ?? '';
    final avatarUrl = userData['avatar_url'] as String?;
    final headline = profile['headline'] as String?;
    final city = profile['city'] as String?;
    final github = profile['github_url'] as String?;
    final linkedin = profile['linkedin_url'] as String?;
    final portfolio = profile['portfolio_url'] as String?;
    final hasLinks = github != null || linkedin != null || portfolio != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HireXAvatar(imageUrl: avatarUrl, name: name, radius: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w700)),
                    if (headline != null && headline.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(headline, style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.75),
                      )),
                    ],
                    if (city != null && city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: AppColors.onSurface.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(city, style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                          )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasLinks) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2A2A4A), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (github != null) _LinkChip(icon: Icons.code_rounded, label: 'GitHub', url: github),
                if (linkedin != null) _LinkChip(icon: Icons.link_rounded, label: 'LinkedIn', url: linkedin),
                if (portfolio != null) _LinkChip(icon: Icons.web_rounded, label: 'Portfolio', url: portfolio),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => launchUrl(Uri.parse(url)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(label, style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ),
      );
}

// ── Bio Card ──────────────────────────────────────────────────────────────────

class _BioCard extends StatefulWidget {
  const _BioCard({required this.bio});
  final String bio;

  @override
  State<_BioCard> createState() => _BioCardState();
}

class _BioCardState extends State<_BioCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.bio.length > 120;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('About', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.bio,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (isLong) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Skills Card ───────────────────────────────────────────────────────────────

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills});
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Skills', style: AppTextStyles.titleSmall),
              const Spacer(),
              Text(
                '${skills.length} skills',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) => HireXTag(label: s, isSelected: true)).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Skill Score Card ──────────────────────────────────────────────────────────

class _SkillScoreCard extends StatelessWidget {
  const _SkillScoreCard({required this.skillScore});
  final Map<String, dynamic> skillScore;

  @override
  Widget build(BuildContext context) {
    final overall = skillScore['overall'] as int? ?? 0;
    final domains = skillScore['domains'] as Map<String, dynamic>? ?? {};
    final percentile = (skillScore['percentile'] as num?)?.toDouble() ?? 0;
    final history = (skillScore['history'] as List<dynamic>?) ?? [];

    return GestureDetector(
      onTap: () => context.push('/candidate/skill-score'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Skill Score', style: AppTextStyles.titleSmall),
                const Spacer(),
                Text(
                  '$overall / 1000',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Top ${(100 - percentile).toStringAsFixed(1)}% overall on HireX',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
            if (domains.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...domains.entries.map((e) {
                final score = (e.value as num).toInt();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DomainBadge(domain: e.key, small: true),
                          const Spacer(),
                          Text('$score', style: AppTextStyles.labelSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearPercentIndicator(
                        lineHeight: 6,
                        percent: (score / 1000).clamp(0.0, 1.0),
                        backgroundColor: AppColors.divider,
                        progressColor: DomainBadge.colorFor(e.key),
                        barRadius: const Radius.circular(3),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (history.length >= 2) ...[
              const SizedBox(height: 8),
              SizedBox(height: 50, child: _ScoreTrendChart(history: history)),
            ],
            const SizedBox(height: 6),
            Text(
              'Score updates after each task is scored',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTrendChart extends StatelessWidget {
  const _ScoreTrendChart({required this.history});
  final List<dynamic> history;

  @override
  Widget build(BuildContext context) {
    final recent = history.take(5).toList().reversed.toList();
    final spots = recent.asMap().entries.map((e) {
      final item = e.value;
      final score = item is Map ? (item['score'] as num?)?.toDouble() ?? 0 : 0.0;
      return FlSpot(e.key.toDouble(), score);
    }).toList();

    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    ));
  }
}

// ── Activity Section ──────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Activity', style: AppTextStyles.titleSmall),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatBox('Attempted', '${stats['tasks_attempted'] ?? 0}', AppColors.primary),
            const SizedBox(width: 10),
            _StatBox('Completed', '${stats['tasks_completed'] ?? 0}', AppColors.success),
            const SizedBox(width: 10),
            _StatBox('Scored', '${stats['tasks_scored'] ?? 0}', const Color(0xFF3B82F6)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatBox('Best Rank', stats['best_rank'] != null ? '#${stats['best_rank']}' : '—', AppColors.warning),
            const SizedBox(width: 10),
            _StatBox('Avg Score', stats['average_score'] != null
                ? '${(stats['average_score'] as num).toStringAsFixed(1)}'
                : '—', AppColors.primary),
            const SizedBox(width: 10),
            _StatBox('Top 10%', '${stats['top_10_percent_finishes'] ?? 0}', AppColors.success),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Text(value, style: AppTextStyles.headlineMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 3),
              Text(label, style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ── Badges Section ────────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.badges});
  final List<dynamic> badges;

  static const _icons = {
    'first_submission': Icons.flag_rounded,
    'top_10': Icons.trending_up_rounded,
    'top_3': Icons.emoji_events_rounded,
    'multi_domain': Icons.diversity_3,
    'streak_5': Icons.local_fire_department_rounded,
    'perfect_score': Icons.star_rounded,
    'speed_demon': Icons.speed_rounded,
    'comeback': Icons.replay_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Badges', style: AppTextStyles.titleSmall),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: badges.length,
          itemBuilder: (_, i) {
            final badge = badges[i] as Map<String, dynamic>;
            final earned = badge['earned'] as bool? ?? false;
            final id = badge['id'] as String;
            final name = badge['name'] as String;
            final icon = _icons[id] ?? Icons.military_tech_rounded;
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: earned ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: earned ? AppColors.primary.withValues(alpha: 0.35) : AppColors.divider,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26,
                    color: earned ? AppColors.primary : AppColors.onSurface.withValues(alpha: 0.25)),
                  const SizedBox(height: 6),
                  Text(name,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: earned ? AppColors.onBackground : AppColors.onSurface.withValues(alpha: 0.35),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!earned)
                    Icon(Icons.lock_outline_rounded, size: 11,
                      color: AppColors.onSurface.withValues(alpha: 0.3)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Task History ──────────────────────────────────────────────────────────────

class _TaskHistorySection extends StatelessWidget {
  const _TaskHistorySection({required this.submissions});
  final List<dynamic> submissions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('Task History', style: AppTextStyles.titleSmall),
            const Spacer(),
            if (submissions.length >= 5)
              GestureDetector(
                onTap: () => context.push('/candidate/my-tasks'),
                child: Text('View All', style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600,
                )),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...submissions.take(5).map((s) {
          final sub = s as Map<String, dynamic>;
          final status = sub['status'] as String? ?? '';
          final totalScore = (sub['total_score'] as num?)?.toDouble();
          final rank = sub['rank'] as int?;
          final submissionId = sub['id'] as String? ?? '';
          final taskTitle = sub['task_title'] as String? ?? 'Task';

          const statusColors = {
            'submitted': Color(0xFF4CAF50),
            'under_review': Color(0xFFFF9800),
            'scored': Color(0xFF3B82F6),
            'rejected': Color(0xFFE94560),
          };
          final statusColor = statusColors[status] ?? const Color(0xFF6B7280);

          return GestureDetector(
            onTap: () => context.push('/candidate/submissions/$submissionId'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_outlined, size: 18, color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(taskTitle, style: AppTextStyles.titleSmall,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(status.replaceAll('_', ' '),
                          style: AppTextStyles.labelSmall.copyWith(color: statusColor)),
                      ],
                    ),
                  ),
                  if (totalScore != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${totalScore.toStringAsFixed(1)}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: totalScore >= 80 ? AppColors.success
                                : totalScore >= 60 ? AppColors.warning : AppColors.error,
                          )),
                        if (rank != null)
                          Text('#$rank', style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.45),
                          )),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Public Profile Toggle ─────────────────────────────────────────────────────

class _PublicProfileToggle extends ConsumerStatefulWidget {
  const _PublicProfileToggle({required this.isPublic});
  final bool isPublic;

  @override
  ConsumerState<_PublicProfileToggle> createState() => _PublicProfileToggleState();
}

class _PublicProfileToggleState extends ConsumerState<_PublicProfileToggle> {
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.isPublic;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (_isPublic ? AppColors.success : AppColors.onSurface).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isPublic ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 18,
                color: _isPublic ? AppColors.success : AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visible to Recruiters', style: AppTextStyles.titleSmall),
                  Text(
                    _isPublic ? 'Your profile is discoverable' : 'Hidden from recruiter search',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isPublic,
              onChanged: (v) {
                setState(() => _isPublic = v);
                ref.read(authNotifierProvider.notifier).updateUser({'public_profile': v});
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      );
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error, required this.onRetry, required this.ref});
  final String error;
  final VoidCallback onRetry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(error, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                child: Text('Sign out', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ),
      );
}
