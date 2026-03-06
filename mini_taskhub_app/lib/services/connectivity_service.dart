import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Singleton
  ConnectivityService._privateConstructor();
  static final ConnectivityService instance =
      ConnectivityService._privateConstructor();

  final Connectivity _connectivity = Connectivity();

  // Internal stream controller to broadcast bool (true = online)
  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get onlineStatus => _onlineStatusController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Call once at app startup to begin listening for connectivity changes.
  Future<void> initialize() async {
    // Check current status immediately
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resultsAreOnline(results);

    // Listen for subsequent changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultsAreOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _onlineStatusController.add(_isOnline);
      }
    });
  }

  bool _resultsAreOnline(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _onlineStatusController.close();
  }
}
