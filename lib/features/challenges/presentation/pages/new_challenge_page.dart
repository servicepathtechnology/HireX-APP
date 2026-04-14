import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/hirex_button.dart';
import '../../domain/entities/challenge_entities.dart';
import '../providers/challenge_providers.dart';

class NewChallengePage extends ConsumerStatefulWidget {
  const NewChallengePage({super.key});

  @override
  ConsumerState<NewChallengePage> createState() => _NewChallengePageState();
}

class _NewChallengePageState extends ConsumerState<NewChallengePage> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();

  Timer? _debounce;
  CancelToken? _cancelToken;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('disposed');
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();

    // Cancel any pending debounce and in-flight request
    _debounce?.cancel();
    _cancelToken?.cancel('new_query');

    if (trimmed.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
        _lastQuery = '';
      });
      return;
    }

    // Show spinner immediately so user knows something is happening
    if (!_isSearching) setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    _cancelToken = CancelToken();
    setState(() {
      _isSearching = true;
      _searchError = null;
      _lastQuery = query;
    });

    try {
      final results = await ref
          .read(challengeRepositoryProvider)
          .searchUsers(query, cancelToken: _cancelToken);
      if (mounted && !(_cancelToken?.isCancelled ?? true)) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = _extractDioError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Fallback: try to load a user profile directly by their user ID.
  /// Works with the existing /api/v1/profile/:userId endpoint.
  // ignore: unused_element
  Future<void> _tryFetchByUserId(String query) async {
    // Only attempt if query looks like a UUID or firebase UID (no spaces, min 20 chars)
    final looksLikeId = !query.contains(' ') && query.length >= 20;
    if (!looksLikeId) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = 'backend_missing'; // special sentinel
      });
      return;
    }

    try {
      final dio = ref.read(challengeDataSourceProvider).dio;
      final res = await dio.get('/api/v1/profile/$query');
      final data = res.data as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      if (user['id'] != null && mounted) {
        setState(() {
          _searchResults = [user];
          _isSearching = false;
          _searchError = null;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchError = 'backend_missing';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchError = 'backend_missing';
        });
      }
    }
  }

  String _extractDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 401) return 'Session expired. Please log in again.';
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'No connection. Check your internet and try again.';
    }
    return 'Search failed (${status ?? 'unknown'}). Try again.';
  }

  void _selectOpponent(Map<String, dynamic> user) {
    ref.read(newChallengeProvider.notifier).setOpponent(user);
    _searchController.clear();
    _debounce?.cancel();
    _cancelToken?.cancel('selected');
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _searchError = null;
      _lastQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newChallengeProvider);
    final notifier = ref.read(newChallengeProvider.notifier);

    ref.listen(newChallengeProvider, (prev, next) {
      if (next.createdMatch != null && prev?.createdMatch == null) {
        // Invalidate providers BEFORE navigating so hub page loads fresh data
        ref.invalidate(myMatchesProvider);
        ref.invalidate(pendingInvitesProvider);
        ref.invalidate(myEloProvider);
        final matchId = next.createdMatch!.id;
        notifier.reset();
        // Navigate to pending status screen (SCR-03)
        context.go('/challenges/1v1/$matchId/pending');
      }
    });

    final showSearchArea = state.selectedOpponent == null &&
        (_isSearching ||
            _searchResults.isNotEmpty ||
            _searchError != null ||
            (_lastQuery.length >= 2 && !_isSearching && _searchResults.isEmpty));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Challenge', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Step 1: Opponent ──────────────────────────────────────────────
          _SectionLabel(label: '1. Select Opponent', icon: Icons.person_search_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
            decoration: InputDecoration(
              hintText: 'Search by username or name...',
              prefixIcon: const Icon(Icons.search, color: AppColors.onSurface),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.onSurface),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),

          if (state.selectedOpponent != null)
            _SelectedOpponentTile(
              opponent: state.selectedOpponent!,
              onRemove: () => notifier.setOpponent(null),
            )
          else if (showSearchArea)
            _SearchResultsPanel(
              isSearching: _isSearching,
              results: _searchResults,
              error: _searchError,
              query: _lastQuery,
              onSelect: _selectOpponent,
            ),

          const SizedBox(height: 28),

          // ── Coding-only banner ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.code_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  '1v1 challenges are Coding only',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Step 2: Difficulty ────────────────────────────────────────────
          _SectionLabel(label: '2. Difficulty Level', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          Row(
            children: ChallengeDifficulty.values.map((d) {
              final selected = state.selectedDifficulty == d;
              final color = _difficultyColor(d);
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setDifficulty(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(_difficultyIcon(d), size: 20,
                            color: selected ? color : AppColors.onSurface),
                        const SizedBox(height: 4),
                        Text(
                          d.label,
                          style: TextStyle(
                            color: selected ? color : AppColors.onSurface,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _difficultySubtitle(d),
                          style: TextStyle(
                            color: (selected ? color : AppColors.onSurface).withValues(alpha: 0.6),
                            fontFamily: 'Inter',
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Step 3: Duration ──────────────────────────────────────────────
          _SectionLabel(label: '3. Match Duration', icon: Icons.timer_rounded),
          const SizedBox(height: 12),
          Row(
            children: [30, 60, 120].map((mins) {
              final selected = state.durationMinutes == mins;
              return Expanded(
                child: GestureDetector(
                  onTap: () => notifier.setDuration(mins),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mins == 120 ? '2h' : '${mins}m',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Text(
                          mins == 120 ? '120 min' : '$mins min',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.onSurface,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ── Step 4: Message ───────────────────────────────────────────────
          _SectionLabel(label: '4. Custom Message (optional)', icon: Icons.message_rounded),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
            maxLength: 200,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add a message to your opponent...',
              counterStyle: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
            ),
            onChanged: notifier.setMessage,
          ),

          const SizedBox(height: 32),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
            ),

          HireXButton(
            label: 'Send Challenge',
            isLoading: state.isLoading,
            onPressed: state.isValid ? notifier.sendInvite : null,
            icon: const Icon(Icons.send_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  IconData _difficultyIcon(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy: return Icons.sentiment_satisfied_rounded;
      case ChallengeDifficulty.medium: return Icons.sentiment_neutral_rounded;
      case ChallengeDifficulty.hard: return Icons.sentiment_very_dissatisfied_rounded;
    }
  }

  Color _difficultyColor(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy: return const Color(0xFF22C55E);
      case ChallengeDifficulty.medium: return const Color(0xFFF59E0B);
      case ChallengeDifficulty.hard: return const Color(0xFFEF4444);
    }
  }

  String _difficultySubtitle(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy: return '200 questions';
      case ChallengeDifficulty.medium: return '200 questions';
      case ChallengeDifficulty.hard: return '100 DSA';
    }
  }
}

// ── Search Results Panel ──────────────────────────────────────────────────────

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel({
    required this.isSearching,
    required this.results,
    required this.error,
    required this.query,
    required this.onSelect,
  });

  final bool isSearching;
  final List<Map<String, dynamic>> results;
  final String? error;
  final String query;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error!,
                  style: const TextStyle(
                    color: AppColors.error, fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty && query.length >= 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded,
                size: 18, color: AppColors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'No users found for "$query"',
              style: const TextStyle(
                color: AppColors.onSurface, fontFamily: 'Inter', fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: results.take(5).map((u) {
          final name = u['full_name'] as String? ?? '';
          final email = u['email'] as String? ?? '';
          final avatar = u['avatar_url'] as String?;
          final isLast = results.indexOf(u) == results.length - 1 ||
              results.indexOf(u) == 4;
          return Column(
            children: [
              InkWell(
                onTap: () => onSelect(u),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceVariant,
                        backgroundImage:
                            avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: Colors.white, fontFamily: 'Inter'),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                                fontSize: 14,
                              ),
                            ),
                            if (email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, color: AppColors.divider, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headlineMedium),
      ],
    );
  }
}

// ── Selected Opponent Tile ────────────────────────────────────────────────────

class _SelectedOpponentTile extends StatelessWidget {
  const _SelectedOpponentTile({required this.opponent, required this.onRemove});
  final Map<String, dynamic> opponent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final name = opponent['full_name'] as String? ?? 'Unknown';
    final avatar = opponent['avatar_url'] as String?;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
            child: avatar == null
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const Text(
                  'Selected ✓',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurface, size: 18),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
