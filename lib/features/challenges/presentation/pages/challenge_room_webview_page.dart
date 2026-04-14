import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/hirex_loader.dart';
import '../providers/challenge_providers.dart';

/// SCR-06 — Challenge Room WebView
///
/// Loads the external challenge room web app inside a Flutter WebView.
/// Listens for postMessage events from the web page:
///   { event: 'RETURN_TO_APP', matchId: '...' }  → navigate to result page
///
/// Route: /challenges/1v1/:matchId/room
class ChallengeRoomWebViewPage extends ConsumerStatefulWidget {
  const ChallengeRoomWebViewPage({super.key, required this.matchId});
  final String matchId;

  @override
  ConsumerState<ChallengeRoomWebViewPage> createState() =>
      _ChallengeRoomWebViewPageState();
}

class _ChallengeRoomWebViewPageState
    extends ConsumerState<ChallengeRoomWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _roomUrl;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _loadRoomUrl();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
        ),
      )
      // Listen for postMessage from the web page
      ..addJavaScriptChannel(
        'HireXBridge',
        onMessageReceived: _handlePostMessage,
      )
      // Inject a listener for window.postMessage events
      ..setOnConsoleMessage((_) {});
  }

  Future<void> _loadRoomUrl() async {
    try {
      // Fetch room URL from backend (or use cached challenge_link)
      final match = await ref.read(challengeRepositoryProvider).getMatch(widget.matchId);
      final url = match.challengeLink;
      if (url == null || url.isEmpty) {
        setState(() => _hasError = true);
        return;
      }
      setState(() => _roomUrl = url);
      await _controller.loadRequest(Uri.parse(url));

      // Inject postMessage bridge after page loads
      await _controller.runJavaScript('''
        window.addEventListener('message', function(e) {
          if (e.data && e.data.event === 'RETURN_TO_APP') {
            HireXBridge.postMessage(JSON.stringify(e.data));
          }
        });
      ''');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _handlePostMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final event = data['event'] as String?;
      if (event == 'RETURN_TO_APP') {
        final matchId = data['matchId'] as String? ?? widget.matchId;
        if (mounted) {
          context.go('/challenges/1v1/$matchId/result');
        }
      }
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Leave Challenge?',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        content: const Text(
          'Leaving will not submit your solution. Your code will be auto-submitted when the timer expires.',
          style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && mounted) {
          context.go('/challenges/1v1');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            if (_hasError)
              _ErrorView(
                onRetry: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                  });
                  _loadRoomUrl();
                },
                onBack: () => context.go('/challenges/1v1'),
              )
            else
              WebViewWidget(controller: _controller),

            if (_isLoading && !_hasError)
              Container(
                color: AppColors.background,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HireXLoader(),
                      SizedBox(height: 16),
                      Text(
                        'Loading challenge room…',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.onBack});
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Could not load challenge room',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(color: AppColors.onSurface, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: const Text('Back to Hub'),
            ),
          ],
        ),
      ),
    );
  }
}
