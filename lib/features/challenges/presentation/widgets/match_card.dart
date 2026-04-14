import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/challenge_entities.dart';

/// Card showing a match in the hub or history list.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.currentUserId,
    this.onAccept,
    this.onDecline,
  });

  final MatchEntity match;
  final String currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  bool get _isChallenger => match.challengerId == currentUserId;

  String get _opponentName =>
      _isChallenger ? (match.opponentName ?? 'Opponent') : (match.challengerName ?? 'Challenger');

  String? get _opponentAvatar =>
      _isChallenger ? match.opponentAvatarUrl : match.challengerAvatarUrl;

  Future<void> _openChallengeRoom(BuildContext context) async {
    final link = match.challengeLink;
    if (link != null && link.isNotEmpty) {
      try {
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    if (context.mounted) {
      context.push('/challenges/1v1/${match.id}/room');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (match.status == MatchStatus.active) {
          _openChallengeRoom(context);
        } else if (match.status == MatchStatus.completed) {
          context.push('/challenges/1v1/${match.id}/result');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: match.status == MatchStatus.active
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: match.status),
                const Spacer(),
                _DomainChip(domain: match.domain),
                const SizedBox(width: 8),
                Text(
                  '${match.durationMinutes}m',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: _opponentAvatar != null
                      ? NetworkImage(_opponentAvatar!)
                      : null,
                  child: _opponentAvatar == null
                      ? Text(
                          _opponentName.isNotEmpty ? _opponentName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isChallenger ? 'You challenged' : 'Challenge from',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        _opponentName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                if (match.taskTitle != null)
                  Flexible(
                    child: Text(
                      match.taskTitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurface,
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            // Active match — show Start Challenge button
            if (match.status == MatchStatus.active) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openChallengeRoom(context),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  label: const Text('Start Challenge',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
            // Pending — show accept/decline for opponent
            if (match.status == MatchStatus.pending && !_isChallenger) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline', style: TextStyle(fontFamily: 'Inter')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept', style: TextStyle(fontFamily: 'Inter')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MatchStatus status;

  Color get _color {
    switch (status) {
      case MatchStatus.pending: return AppColors.warning;
      case MatchStatus.active: return AppColors.success;
      case MatchStatus.completed: return AppColors.onSurface;
      case MatchStatus.cancelled: return AppColors.error;
      case MatchStatus.expired: return AppColors.error;
    }
  }

  String get _label {
    switch (status) {
      case MatchStatus.pending: return 'Pending';
      case MatchStatus.active: return 'Live';
      case MatchStatus.completed: return 'Completed';
      case MatchStatus.cancelled: return 'Cancelled';
      case MatchStatus.expired: return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == MatchStatus.active)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  const _DomainChip({required this.domain});
  final ChallengeDomain domain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        domain.label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.onSurface,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
