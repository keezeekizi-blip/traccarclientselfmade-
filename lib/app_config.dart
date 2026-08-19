class AppConfig {
  static const registrationUrl = String.fromEnvironment(
    'REGISTRATION_URL',
    defaultValue: 'https://tracker-register.tail27cc92.ts.net',
  );

  static const traccarUrl = String.fromEnvironment(
    'TRACCAR_URL',
    defaultValue: 'https://traccar.tail27cc92.ts.net:8443',
  );
}
