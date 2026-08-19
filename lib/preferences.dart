import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:traccar_client_sdk/traccar_client_sdk.dart';

class Preferences {
  static Future<void>? _initFuture;
  static late SharedPreferencesWithCache instance;

  static const String id = 'id';
  static const String username = 'username';
  static const String registered = 'registered';
  static const String url = 'url';
  static const String accuracy = 'accuracy';
  static const String distance = 'distance';
  static const String interval = 'interval';
  static const String angle = 'angle';
  static const String heartbeat = 'heartbeat';
  static const String buffer = 'buffer';
  static const String wakelock = 'wakelock';
  static const String stopDetection = 'stop_detection';
  static const String preferPlatformProviders = 'prefer_platform_providers';
  static const String password = 'password';
  static const String trackingEnabled = 'tracking_enabled';

  static const String defaultUrl = 'https://traccar.tail27cc92.ts.net:8443';

  static Future<void> init() async {
    _initFuture ??= _createInstance();
    await _initFuture;
  }

  static Future<void> _createInstance() async {
    instance = await SharedPreferencesWithCache.create(
      sharedPreferencesOptions: Platform.isAndroid
          ? SharedPreferencesAsyncAndroidOptions(
              backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
            )
          : SharedPreferencesOptions(),
      cacheOptions: SharedPreferencesWithCacheOptions(
        allowList: {
          id,
          username,
          registered,
          url,
          accuracy,
          distance,
          interval,
          angle,
          heartbeat,
          buffer,
          wakelock,
          stopDetection,
          preferPlatformProviders,
          password,
          trackingEnabled,
        },
      ),
    );

    if (Platform.isAndroid) {
      for (final key in {interval, distance, angle, heartbeat}) {
        if (instance.get(key) is String) {
          await instance.setInt(
            key,
            int.tryParse(instance.getString(key) ?? '') ?? 0,
          );
        }
      }
    }

    if (instance.getString(url) == null) {
      await instance.setString(url, defaultUrl);
    }
    if (instance.getString(accuracy) == null) {
      await instance.setString(accuracy, 'medium');
    }
    if (instance.getInt(interval) == null) {
      await instance.setInt(interval, 300);
    }
    if (instance.getInt(distance) == null) {
      await instance.setInt(distance, 75);
    }
    if (instance.getBool(buffer) == null) {
      await instance.setBool(buffer, true);
    }
    if (instance.getBool(stopDetection) == null) {
      await instance.setBool(stopDetection, true);
    }
    if (instance.getBool(registered) == null) {
      await instance.setBool(registered, false);
    }
    if (instance.getBool(trackingEnabled) == null) {
      await instance.setBool(trackingEnabled, false);
    }
  }

  static bool get isRegistered => instance.getBool(registered) ?? false;

  static Config buildConfig() {
    return Config(
      serverUrl: instance.getString(url) ?? defaultUrl,
      deviceId: instance.getString(id) ?? '',
      location: LocationConfig(
        accuracy: switch (instance.getString(accuracy)) {
          'highest' => Accuracy.highest,
          'high' => Accuracy.high,
          'low' => Accuracy.low,
          _ => Accuracy.medium,
        },
        distanceMeters: instance.getInt(distance) ?? 75,
        intervalSeconds: instance.getInt(interval) ?? 300,
        angleDegrees: instance.getInt(angle) ?? 0,
        heartbeatIntervalSeconds: instance.getInt(heartbeat) ?? 0,
        stopDetection: instance.getBool(stopDetection) ?? true,
      ),
      wakeLock: instance.getBool(wakelock) ?? false,
      buffer: instance.getBool(buffer) ?? true,
      preferPlatformProviders: instance.getBool(preferPlatformProviders) ?? false,
    );
  }
}
