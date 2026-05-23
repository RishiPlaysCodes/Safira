import 'package:url_launcher/url_launcher.dart';

/// Enhanced emergency service with live location sharing in messages
class EmergencyService {
  Future<bool> openSms({
    required String phone,
    required String mapsLink,
  }) async {
    if (phone.isEmpty) return false;

    final message = Uri.encodeComponent(
      'SafeRide Guardian Alert: Possible accident/emergency detected.\n'
      'Live Location: $mapsLink\n'
      'Please check immediately!',
    );
    final uri = Uri.parse('sms:$phone?body=$message');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  Future<bool> openSmsWithMessage({
    required String phone,
    required String message,
  }) async {
    if (phone.isEmpty) return false;

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encoded');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  Future<bool> openCall({required String phone}) async {
    if (phone.isEmpty) return false;

    final uri = Uri.parse('tel:$phone');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  /// Call ambulance (108 in India, 911 in US)
  Future<bool> callAmbulance({String number = '108'}) async {
    final uri = Uri.parse('tel:$number');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  /// Share location via any app (WhatsApp, etc.)
  Future<bool> shareLocation({
    required String phone,
    required double latitude,
    required double longitude,
    required String riderName,
    String? liveTrackingLink,
  }) async {
    final googleLink = 'https://maps.google.com/?q=$latitude,$longitude';
    final message = 'SafeRide Guardian - Emergency!\n'
        'Rider: $riderName\n'
        'Location: $googleLink\n'
        '${liveTrackingLink != null ? "Live Tracking: $liveTrackingLink\n" : ""}'
        'Please respond immediately!';

    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:$phone?body=$encoded');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
