import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class BackendManager {
  static Process? _backendProcess;

  /// Start the bundled backend executable silently if found
  static Future<void> start() async {
    if (!Platform.isWindows) return;

    try {
      // 1. Clean up any stale/orphaned backend instances from previous sessions
      _killExistingBackendInstances();

      final exePath = _resolveBackendExecutablePath();

      if (exePath != null && File(exePath).existsSync()) {
        debugPrint('[BackendManager] Starting backend at: $exePath');
        _backendProcess = await Process.start(
          exePath,
          [],
          mode: ProcessStartMode.detached, // Run silently in background without console window
        );

        debugPrint('[BackendManager] Backend process spawned (PID: ${_backendProcess?.pid})');
        await waitForBackendReady();
      } else {
        debugPrint('[BackendManager] Standalone backend executable not found. Assuming external server or dev mode.');
      }
    } catch (e) {
      debugPrint('[BackendManager] Error starting backend process: $e');
    }
  }

  /// Locate the backend executable across release, installed, and debug paths
  static String? _resolveBackendExecutablePath() {
    final List<String> candidatePaths = [];

    try {
      // 1. Next to the running Flutter .exe in /backend/
      final appDir = File(Platform.resolvedExecutable).parent.path;
      candidatePaths.add('$appDir\\backend\\dentium_backend.exe');
      candidatePaths.add('$appDir\\backend\\dentium_backend\\dentium_backend.exe');
    } catch (_) {}

    // 2. Relative to the current working directory
    final currentPath = Directory.current.path;
    candidatePaths.add('$currentPath\\backend\\dentium_backend.exe');
    candidatePaths.add('$currentPath\\dist\\dentium_backend\\dentium_backend.exe');

    for (final path in candidatePaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    return null;
  }

  /// Poll health endpoint until backend is ready
  static Future<bool> waitForBackendReady({
    String healthUrl = 'http://127.0.0.1:8000/api/health',
    int maxAttempts = 15,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final request = await client.getUrl(Uri.parse(healthUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          debugPrint('[BackendManager] Backend is ready and responding at $healthUrl (attempt ${i + 1})');
          client.close();
          return true;
        }
      } catch (_) {
        // Retry if not yet ready
      }
      await Future.delayed(delay);
    }

    client.close();
    debugPrint('[BackendManager] Backend readiness check timed out after $maxAttempts attempts.');
    return false;
  }

  /// Forcefully terminate all backend processes and child sub-processes
  static void stop() {
    if (_backendProcess != null) {
      final pid = _backendProcess!.pid;
      debugPrint('[BackendManager] Terminating backend process tree (PID: $pid)...');
      try {
        // Use Windows taskkill with /T (tree/all child processes) and /F (force)
        Process.runSync('taskkill', ['/F', '/T', '/PID', '$pid']);
      } catch (e) {
        debugPrint('[BackendManager] Taskkill by PID error: $e');
      }
      try {
        _backendProcess?.kill();
      } catch (_) {}
      _backendProcess = null;
    }

    // Safety sweep for dentium_backend.exe
    _killExistingBackendInstances();
  }

  /// Helper to kill any stray dentium_backend.exe instances
  static void _killExistingBackendInstances() {
    if (!Platform.isWindows) return;
    try {
      Process.runSync('taskkill', ['/F', '/IM', 'dentium_backend.exe', '/T']);
    } catch (_) {
      // Ignored if no process was running
    }
  }
}
