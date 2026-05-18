import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  Future<bool> openSms({
    required String phone,
    required String mapsLink,
  }) async {
    if (phone.isEmpty) return false;

    final message = Uri.encodeComponent(
      'SafeRide Guardian Alert: Possible accident/emergency detected. Location: $mapsLink',
    );
    final uri = Uri.parse('sms:$phone?body=$message');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  Future<bool> openCall({required String phone}) async {
    if (phone.isEmpty) return false;

    final uri = Uri.parse('tel:$phone');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
