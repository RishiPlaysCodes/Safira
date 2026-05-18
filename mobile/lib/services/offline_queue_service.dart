import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineQueueService {
  static const _tripQueueKey = 'pending_trip_queue';
  static const _alertQueueKey = 'pending_alert_queue';

  Future<void> addTrip(Map<String, dynamic> payload) async {
    await _append(_tripQueueKey, payload);
  }

  Future<void> addAlert(Map<String, dynamic> payload) async {
    await _append(_alertQueueKey, payload);
  }

  Future<List<Map<String, dynamic>>> loadTrips() async {
    return _load(_tripQueueKey);
  }

  Future<List<Map<String, dynamic>>> loadAlerts() async {
    return _load(_alertQueueKey);
  }

  Future<void> replaceTrips(List<Map<String, dynamic>> items) async {
    await _replace(_tripQueueKey, items);
  }

  Future<void> replaceAlerts(List<Map<String, dynamic>> items) async {
    await _replace(_alertQueueKey, items);
  }

  Future<void> _append(String key, Map<String, dynamic> payload) async {
    final items = await _load(key);
    items.add(payload);
    await _replace(key, items);
  }

  Future<List<Map<String, dynamic>>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? [];
    return raw
        .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
        .toList();
  }

  Future<void> _replace(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      items.map((item) => jsonEncode(item)).toList(),
    );
  }
}
