import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Navigation mode constants passed to [MapLauncherService].
abstract final class NavMode {
  static const String driving = 'd';
  static const String walking = 'w';
}

/// Launches external map applications for turn-by-turn navigation.
///
/// Android: tries the native `google.navigation:` URI first (opens Google Maps
/// directly into navigation), falls back to a universal HTTPS Google Maps URL.
///
/// iOS: exposes [launchGoogleMaps] and [launchAppleMaps] separately so the UI
/// can show a picker sheet and call whichever the user selects.
abstract final class MapLauncherService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns true if Google Maps is installed on the device.
  static Future<bool> isGoogleMapsInstalled() async {
    try {
      if (Platform.isAndroid) {
        return canLaunchUrl(Uri.parse('google.navigation:q=0,0&mode=d'));
      }
      return canLaunchUrl(Uri.parse('comgooglemaps://'));
    } catch (_) {
      return false;
    }
  }

  /// Launches Google Maps navigation to [lat]/[lng].
  ///
  /// [mode] is [NavMode.driving] or [NavMode.walking].
  ///
  /// On Android: uses `google.navigation:` URI (opens navigation view directly).
  /// On iOS: uses `comgooglemaps://` deep-link URI.
  /// Falls back to `https://www.google.com/maps/dir/` in both cases when the
  /// native URI is not launchable.
  static Future<void> launchGoogleMaps(
      double lat, double lng, String mode) async {
    try {
      final travelMode = mode == NavMode.walking ? 'walking' : 'driving';

      if (!kIsWeb && Platform.isAndroid) {
        final nativeUri =
            Uri.parse('google.navigation:q=$lat,$lng&mode=$mode');
        if (await canLaunchUrl(nativeUri)) {
          await launchUrl(nativeUri);
          return;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        final iosUri = Uri.parse(
            'comgooglemaps://?daddr=$lat,$lng&directionsmode=$travelMode');
        if (await canLaunchUrl(iosUri)) {
          await launchUrl(iosUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      // Universal web fallback
      final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$lat,$lng&travelmode=$travelMode',
      );
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MapLauncherService] launchGoogleMaps error: $e');
    }
  }

  /// Launches Apple Maps navigation to [lat]/[lng].
  ///
  /// [mode] is [NavMode.driving] (`d`) or [NavMode.walking] (`w`).
  ///
  /// Only meaningful on iOS — `maps.apple.com` redirects to Apple Maps on device.
  static Future<void> launchAppleMaps(
      double lat, double lng, String mode) async {
    try {
      final uri =
          Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&dirflg=$mode');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MapLauncherService] launchAppleMaps error: $e');
    }
  }
}
