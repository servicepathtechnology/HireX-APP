import '../entities/challenge_entities.dart';

/// ELO calculation utility.
/// K-factor: 32, Starting ELO: 1000
/// Draw threshold: scores within 2 points.
class EloCalculator {
  static const int kFactor = 32;
  static const int startingElo = 1000;

  /// Expected score for player A against player B.
  static double expectedScore(int eloA, int eloB) {
    return 1.0 / (1.0 + _pow10((eloB - eloA) / 400.0));
  }

  /// Calculate new ELO for both players.
  /// [scoreA] and [scoreB] are 0–100 evaluation scores.
  /// Returns (newEloA, newEloB).
  static (int, int) calculate({
    required int eloA,
    required int eloB,
    required int? scoreA,
    required int? scoreB,
  }) {
    final result = _determineResult(scoreA, scoreB);
    final expA = expectedScore(eloA, eloB);
    final expB = expectedScore(eloB, eloA);

    final newEloA = (eloA + kFactor * (result.actualA - expA)).round();
    final newEloB = (eloB + kFactor * (result.actualB - expB)).round();

    return (newEloA.clamp(0, 9999), newEloB.clamp(0, 9999));
  }

  static _MatchResult _determineResult(int? scoreA, int? scoreB) {
    // One submitted, other didn't
    if (scoreA != null && scoreB == null) return const _MatchResult(1.0, 0.0);
    if (scoreA == null && scoreB != null) return const _MatchResult(0.0, 1.0);
    // Neither submitted
    if (scoreA == null && scoreB == null) return const _MatchResult(0.5, 0.5);

    final diff = (scoreA! - scoreB!).abs();
    if (diff <= 2) return const _MatchResult(0.5, 0.5); // Draw
    if (scoreA > scoreB) return const _MatchResult(1.0, 0.0);
    return const _MatchResult(0.0, 1.0);
  }

  static double _pow10(double x) => _exp(x * _ln10);
  static const double _ln10 = 2.302585092994046;
  static double _exp(double x) {
    // Taylor series approximation — sufficient for ELO range
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  static EloTier tierFromElo(int elo) => EloTierX.fromElo(elo);
}

class _MatchResult {
  const _MatchResult(this.actualA, this.actualB);
  final double actualA;
  final double actualB;
}
