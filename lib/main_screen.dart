import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'geolocation_service.dart';
import 'preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _tracking = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureTracking();
    }
  }

  Future<void> _ensureTracking() async {
    if (_starting || !Preferences.isRegistered) return;
    final alreadyTracking = await GeolocationService.tracker.isTracking();
    if (alreadyTracking) {
      if (mounted) setState(() => _tracking = true);
      return;
    }

    if (mounted) setState(() => _starting = true);
    try {
      await GeolocationService.tracker.start();
      if (mounted) setState(() => _tracking = true);
    } on PlatformException {
      if (mounted) setState(() => _tracking = false);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void refresh() => _ensureTracking();

  @override
  Widget build(BuildContext context) {
    final nickname = Preferences.instance.getString(Preferences.nickname) ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Tracker')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _tracking ? Icons.location_on : Icons.location_searching,
                size: 72,
              ),
              const SizedBox(height: 24),
              Text(
                'Hallo $nickname',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _tracking
                    ? 'Dein Standort wird automatisch übertragen.'
                    : _starting
                        ? 'Tracking wird gestartet …'
                        : 'Standortzugriff wird benötigt, damit das Tracking starten kann.',
                textAlign: TextAlign.center,
              ),
              if (!_tracking && !_starting) ...[
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: _ensureTracking,
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
