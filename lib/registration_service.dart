import 'dart:convert';
import 'dart:io';

class RegistrationResult {
  final String nickname;
  final String uniqueId;

  const RegistrationResult({required this.nickname, required this.uniqueId});
}

class RegistrationService {
  static const String registrationUrl =
      'https://tracker-register.tail27cc92.ts.net/register';

  static Future<RegistrationResult> register(String nickname) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(registrationUrl));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'nickname': nickname.trim()}));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300 ||
          data['success'] != true || data['uniqueId'] == null) {
        throw RegistrationException(
          data['error']?.toString() ??
              'Registrierung fehlgeschlagen (HTTP ${response.statusCode}).',
        );
      }

      return RegistrationResult(
        nickname: data['nickname']?.toString() ?? nickname.trim(),
        uniqueId: data['uniqueId'].toString(),
      );
    } on RegistrationException {
      rethrow;
    } on SocketException {
      throw const RegistrationException(
        'Der Registrierungsserver ist nicht erreichbar.',
      );
    } on FormatException {
      throw const RegistrationException(
        'Ungültige Antwort vom Registrierungsserver.',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class RegistrationException implements Exception {
  final String message;

  const RegistrationException(this.message);

  @override
  String toString() => message;
}
