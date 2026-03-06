import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// A widget that wraps [child] and shows an animated connectivity banner
/// at the top of the screen when the device is offline (or just came back online).
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  final _connectivity = ConnectivityService.instance;

  late bool _isOnline;
  bool _justCameOnline = false;
  StreamSubscription<bool>? _sub;
  Timer? _backOnlineTimer;

  late AnimationController _controller;
  late Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isOnline;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (!_isOnline) _controller.forward();

    _sub = _connectivity.onlineStatus.listen((online) {
      if (!mounted) return;
      final wasOffline = !_isOnline;
      setState(() => _isOnline = online);

      if (online) {
        if (wasOffline) {
          setState(() => _justCameOnline = true);
          _backOnlineTimer?.cancel();
          _backOnlineTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _justCameOnline = false);
            _controller.reverse();
          });
        } else {
          _controller.reverse();
        }
      } else {
        _justCameOnline = false;
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _backOnlineTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizeTransition(
          sizeFactor: _heightAnim,
          axisAlignment: -1,
          child: _buildBanner(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBanner() {
    final isOnlineBanner = _justCameOnline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: isOnlineBanner
          ? const Color(0xFF22C55E) // green
          : const Color(0xFFF59E0B), // amber
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnlineBanner
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isOnlineBanner
                  ? '✓ Back online! Syncing your changes...'
                  : '📡 Offline — changes will sync when you reconnect',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
