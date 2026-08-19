class AppConfig {
  static const registrationUrl = String.fromEnvironment(
    'REGISTRATION_URL',
    defaultValue: 'http://192.168.8.183:8090',
  );

  static const traccarUrl = String.fromEnvironment(
    'TRACCAR_URL',
    defaultValue: 'https://traccar.tail27cc92.ts.net:8443',
  );
}
