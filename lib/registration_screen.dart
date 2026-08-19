import 'package:flutter/material.dart';

import 'geolocation_service.dart';
import 'preferences.dart';
import 'registration_service.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  const RegistrationScreen({super.key, required this.onRegistered});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nickname = _controller.text.trim();
    if (nickname.length < 2 || nickname.length > 40) {
      setState(() => _error = 'Der Benutzername muss 2 bis 40 Zeichen lang sein.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await RegistrationService.register(nickname);

      await Preferences.instance.setString(Preferences.username, result.nickname);
      await Preferences.instance.setString(Preferences.id, result.uniqueId);
      await Preferences.instance.setString(Preferences.url, Preferences.defaultUrl);
      await Preferences.instance.setBool(Preferences.registered, true);
      await Preferences.instance.setBool(Preferences.trackingEnabled, false);

      await GeolocationService.tracker.init(Preferences.buildConfig());

      if (!mounted) return;
      widget.onRegistered();
    } on RegistrationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Registrierung fehlgeschlagen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker einrichten')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Wähle deinen Benutzernamen',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Der Benutzername wird einmalig beim Tracker-Server registriert. Danach wird diesem Gerät automatisch eine eigene Geräte-ID zugewiesen und das Tracking gestartet.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _controller,
                    enabled: !_busy,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _register(),
                    decoration: const InputDecoration(
                      labelText: 'Benutzername',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _register,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrieren und Tracking starten'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
