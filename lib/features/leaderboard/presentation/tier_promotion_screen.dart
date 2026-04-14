import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:hirex_app/features/leaderboard/presentation/widgets/tier_badge.dart';
import 'package:share_plus/share_plus.dart';

class TierPromotionScreen extends StatefulWidget {
  final String newTier;
  final int newElo;
  final int? newRank;

  const TierPromotionScreen({
    super.key,
    required this.newTier,
    required this.newElo,
    this.newRank,
  });

  @override
  State<TierPromotionScreen> createState() => _TierPromotionScreenState();
}

class _TierPromotionScreenState extends State<TierPromotionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Trigger haptic feedback
    HapticFeedback.heavyImpact();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierColor = _getTierColor(widget.newTier);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: SafeArea(
        child: Stack(
          children: [
            // Background particles/confetti animation
            Positioned.fill(
              child: Lottie.asset(
                'assets/animations/confetti.json',
                repeat: false,
                fit: BoxFit.cover,
              ),
            ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated tier badge
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tierColor.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: TierBadge(
                        tier: widget.newTier,
                        size: 160,
                        showGlow: true,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // "TIER UP!" text
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'TIER UP!',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // New tier name
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'You are now ${widget.newTier.toUpperCase()}!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ELO display
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: tierColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'ELO: ${widget.newElo}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // New perks
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Perks Unlocked:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._getPerks(widget.newTier).map((perk) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: tierColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      perk,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  if (widget.newRank != null) ...[
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Your new global rank: #${widget.newRank}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Action buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _sharePromotion,
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tierColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Let's Go!",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
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

  void _sharePromotion() {
    Share.share(
      'I just reached ${widget.newTier.toUpperCase()} tier on HireX! '
      'ELO: ${widget.newElo} 🎉 #HireX #TierUp',
    );
  }

  List<String> _getPerks(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return [
          'ELO badge visible to recruiters',
          'Appears in Rising Talent filter',
          'Country leaderboard highlighted',
        ];
      case 'gold':
        return [
          'Priority in recruiter talent search',
          'Gold frame on profile avatar',
          'Domain leaderboard top section',
        ];
      case 'platinum':
        return [
          'Featured in Platinum+ Talent feed',
          'Weekly challenge top 50 badge',
          'Platinum border on results',
        ];
      case 'diamond':
        return [
          'Invited to weekly tournaments',
          'Diamond sparkle animation',
          'Top 5% global ranking badge',
        ];
      case 'elite':
        return [
          'Top Talent Discovery Feed',
          'Verified Elite badge',
          'Priority support',
        ];
      default:
        return [
          'Access to all challenges',
          'Match history visible',
          'Global leaderboard participation',
        ];
    }
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      case 'elite':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }
}
