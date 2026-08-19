import 'dart:convert';
import 'dart:io';

import 'app_config.dart';
import 'preferences.dart';

class RegistrationException implements Exception {
  final String message;

  const RegistrationException(this.message);

  @override
  String toString() => message;
}

class RegistrationService {
  static Future<void> register(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.length < 2 || trimmed.length > 32) {
      throw const RegistrationException('Bitte einen Nickname mit 2 bis 32 Zeichen eingeben.');
    }

    final client = HttpClient();
    try {
      final uri = Uri.parse('${AppConfig.registrationUrl}/register');
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'nickname': trimmed}));

      final response = await request.close().timeout(const Duration(seconds: 15));
      final body = await utf8.decoder.bind(response).join();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        throw const RegistrationException('Der Registrierungsserver hat eine ungültige Antwort gesendet.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] != true) {
        throw RegistrationException(
          data['message']?.toString() ?? 'Registrierung fehlgeschlagen. Bitte versuche es erneut.',
        );
      }

      final userId = data['userId'];
      final deviceId = data['deviceId'];
      final uniqueId = data['uniqueId']?.toString();
      final returnedNickname = data['nickname']?.toString() ?? trimmed;
      if (userId == null || deviceId == null || uniqueId == null || uniqueId.isEmpty) {
        throw const RegistrationException('Die Registrierung wurde ohne vollständige Gerätedaten bestätigt.');
      }

      await Preferences.instance.setString(Preferences.nickname, returnedNickname);
      await Preferences.instance.setString(Preferences.userId, userId.toString());
      await Preferences.instance.setString(Preferences.deviceId, deviceId.toString());
      await Preferences.instance.setString(Preferences.id, uniqueId);
      await Preferences.instance.setString(Preferences.url, AppConfig.traccarUrl);
    } on RegistrationException {
      rethrow;
    } on SocketException {
      throw const RegistrationException('Registrierung fehlgeschlagen. Bitte überprüfe deine Internetverbindung.');
    } on TimeoutException {
      throw const RegistrationException('Der Registrierungsserver antwortet nicht. Bitte versuche es später erneut.');
    } catch (_) {
      throw const RegistrationException('Registrierung fehlgeschlagen. Bitte versuche es erneut.');
    } finally {
      client.close(force: true);
    }
  }
}
