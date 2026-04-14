/// Part 2 — Solo Coding Room WebView Page
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SoloRoomWebViewPage extends ConsumerStatefulWidget {
  final String roomUrl;
  final String roomToken;

  const SoloRoomWebViewPage({
    super.key,
    required this.roomUrl,
    required this.roomToken,
  });

  @override
  ConsumerState<SoloRoomWebViewPage> createState() => _SoloRoomWebViewPageState();
}

class _SoloRoomWebViewPageState extends ConsumerState<SoloRoomWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final fullUrl = '${widget.roomUrl}?token=${widget.roomToken}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(fullUrl));
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'RETURN_TO_APP') {
        // Challenge completed, return to hub
        context.go('/challenges/solo');
      } else if (type == 'CHALLENGE_SUBMITTED') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge submitted successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solo Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit Challenge?'),
                content: const Text('Your progress will be saved.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
