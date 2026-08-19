import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:traccar_client_sdk/traccar_client_sdk.dart';

import 'app_config.dart';

class Preferences {
  static Future<void>? _initFuture;
  static late SharedPreferencesWithCache instance;

  static const String id = 'id';
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
  static const String nickname = 'nickname';
  static const String userId = 'user_id';
  static const String deviceId = 'device_id';

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
          nickname,
          userId,
          deviceId,
        },
      ),
    );
    if (Platform.isAndroid) {
      for (final key in {interval, distance, angle, heartbeat}) {
        if (instance.get(key) is String) {
          await instance.setInt(key, int.tryParse(instance.getString(key) ?? '') ?? 0);
        }
      }
    }
    if (instance.getString(id) == null) {
      await instance.setString(id, (Random().nextInt(90000000) + 10000000).toString());
      await instance.setString(url, AppConfig.traccarUrl);
      await instance.setString(accuracy, 'medium');
      await instance.setInt(interval, 300);
      await instance.setInt(distance, 75);
      await instance.setBool(buffer, true);
      await instance.setBool(stopDetection, true);
    }
  }

  static bool get isRegistered =>
      (instance.getString(nickname)?.isNotEmpty ?? false) &&
      (instance.getString(deviceId)?.isNotEmpty ?? false) &&
      (instance.getString(id)?.isNotEmpty ?? false);

  static Config buildConfig() {
    return Config(
      serverUrl: instance.getString(url) ?? AppConfig.traccarUrl,
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
