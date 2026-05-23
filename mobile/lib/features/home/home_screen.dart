import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/traffic_service.dart';
import '../map/map_screen.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final HomeController controller;
  late final TextEditingController parentPhoneController;
  late final TextEditingController backendUrlController;
  late final TextEditingController usernameController;
  late final TextEditingController destinationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    controller = HomeController()..addListener(_refresh);
    parentPhoneController = TextEditingController();
    backendUrlController = TextEditingController();
    usernameController = TextEditingController();
    destinationController = TextEditingController();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    await controller.loadSettings();
    parentPhoneController.text = controller.parentPhone;
    backendUrlController.text = controller.backendUrl;
    usernameController.text = controller.username;
    destinationController.text = controller.destination;
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    parentPhoneController.dispose();
    backendUrlController.dispose();
    usernameController.dispose();
    destinationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overspeed = controller.speedKmh > controller.speedLimitKmh;
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0E21), Color(0xFF1A1F3A), Color(0xFF0A0E21)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSpeedometer(overspeed),
                  const SizedBox(height: 16),
                  _buildMetricsRow(),
                  const SizedBox(height: 14),
                  if (controller.accidentSuspicion) ...[
                    _buildAccidentAlert(), const SizedBox(height: 14),
                  ],
                  _buildActionButtons(),
                  const SizedBox(height: 14),
                  _buildTrafficCard(),
                  const SizedBox(height: 14),
                  _buildLiveLocationCard(),
                  const SizedBox(height: 14),
                  _buildRideAnalysis(),
                  const SizedBox(height: 14),
                  _buildSettingsCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [SafeRideTheme.accentBlue, SafeRideTheme.accentCyan],
          ).createShader(bounds),
          child: const Text('SafeRide', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
        const Text('Guardian', style: TextStyle(fontSize: 14, color: SafeRideTheme.textSecondary, letterSpacing: 3)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          _chip(controller.tracking ? 'TRACKING' : 'STANDBY',
            controller.tracking ? SafeRideTheme.neonGreen : SafeRideTheme.textSecondary),
          _chip(controller.autoOnEnabled ? 'AUTO-ON' : 'MANUAL', SafeRideTheme.accentPurple),
          if (controller.liveLocationSharing)
            _chip('LIVE', SafeRideTheme.dangerRed),
        ]),
      ])),
      GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MapScreen(
            latitude: controller.latitude, longitude: controller.longitude,
            routeSamples: controller.routeSamples,
          ),
        )),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: SafeRideTheme.glassCard(opacity: 0.1, borderRadius: 16),
          child: const Icon(Icons.map_outlined, color: SafeRideTheme.accentBlue, size: 28),
        ),
      ),
    ]);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }

  Widget _buildSpeedometer(bool overspeed) {
    final color = overspeed ? SafeRideTheme.dangerRed : SafeRideTheme.accentCyan;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = overspeed ? 1.0 + (_pulseController.value * 0.02) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.15), SafeRideTheme.cardDark.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 2)],
        ),
        child: Column(children: [
          Text(controller.tracking ? 'CURRENT SPEED' : 'READY TO RIDE',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(controller.speedKmh.toStringAsFixed(0),
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: color, height: 1)),
            const SizedBox(width: 4),
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text('km/h', style: TextStyle(fontSize: 16, color: color.withValues(alpha: 0.7)))),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: overspeed ? SafeRideTheme.dangerRed.withValues(alpha: 0.2) : SafeRideTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              overspeed ? 'OVERSPEED - SLOW DOWN!' : 'Safe Speed Range',
              style: TextStyle(color: overspeed ? SafeRideTheme.dangerRed : SafeRideTheme.neonGreen,
                fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          Text('Limit: ${controller.speedLimitKmh.toStringAsFixed(0)} km/h',
            style: const TextStyle(color: SafeRideTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(children: [
      Expanded(child: _metricTile(Icons.gps_fixed, 'GPS',
        (controller.latitude != 0) ? 'Locked' : 'Waiting',
        SafeRideTheme.neonGreen)),
      const SizedBox(width: 10),
      Expanded(child: _metricTile(Icons.vibration, 'Impact',
        '${controller.impactG.toStringAsFixed(2)}g',
        controller.impactG > 2 ? SafeRideTheme.dangerRed : SafeRideTheme.accentBlue)),
      const SizedBox(width: 10),
      Expanded(child: _metricTile(Icons.speed, 'Max',
        '${controller.maxSpeedToday.toStringAsFixed(0)}',
        SafeRideTheme.warningOrange)),
    ]);
  }

  Widget _metricTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SafeRideTheme.glassCard(opacity: 0.06),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: SafeRideTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildAccidentAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          SafeRideTheme.dangerRed.withValues(alpha: 0.25), SafeRideTheme.warningOrange.withValues(alpha: 0.15)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SafeRideTheme.dangerRed.withValues(alpha: 0.5)),
        boxShadow: SafeRideTheme.neonGlow(SafeRideTheme.dangerRed, intensity: 0.3),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_rounded, color: SafeRideTheme.dangerRed, size: 28),
          const SizedBox(width: 10),
          const Expanded(child: Text('ACCIDENT DETECTED', style: TextStyle(
            color: SafeRideTheme.dangerRed, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SafeRideTheme.dangerRed, borderRadius: BorderRadius.circular(20)),
            child: Text('${controller.countdown}s', style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('Guardian will be alerted automatically. Tap below if safe.',
          style: TextStyle(color: SafeRideTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: controller.markSafe,
            icon: const Icon(Icons.check_circle),
            label: const Text('I AM SAFE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SafeRideTheme.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(
            onPressed: controller.confirmAccidentNow,
            icon: const Icon(Icons.sos, color: SafeRideTheme.dangerRed),
            label: const Text('ALERT NOW', style: TextStyle(color: SafeRideTheme.dangerRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: SafeRideTheme.dangerRed),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
        ]),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(child: _glassButton(
        icon: controller.tracking ? Icons.stop_circle : Icons.play_circle,
        label: controller.tracking ? 'STOP' : 'START',
        color: controller.tracking ? SafeRideTheme.warningOrange : SafeRideTheme.neonGreen,
        onTap: () async {
          if (controller.tracking) { await controller.stopTracking(); }
          else {
            final ok = await controller.startTracking();
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location permission required')));
            }
          }
        },
      )),
      const SizedBox(width: 10),
      Expanded(child: _glassButton(
        icon: Icons.sos, label: 'SOS',
        color: SafeRideTheme.dangerRed,
        onTap: controller.manualSos,
      )),
      const SizedBox(width: 10),
      Expanded(child: _glassButton(
        icon: Icons.share_location, label: 'SHARE',
        color: SafeRideTheme.accentPurple,
        onTap: controller.shareLiveLocationWithGuardian,
      )),
    ]);
  }

  Widget _glassButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ]),
      ),
    );
  }

  Widget _buildTrafficCard() {
    final tColor = switch (controller.trafficLevel) {
      TrafficLevel.free => SafeRideTheme.neonGreen,
      TrafficLevel.moderate => SafeRideTheme.warningOrange,
      TrafficLevel.heavy => SafeRideTheme.dangerRed,
      TrafficLevel.severe => SafeRideTheme.dangerRed,
      _ => SafeRideTheme.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SafeRideTheme.glassCard(opacity: 0.06),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.traffic, color: tColor, size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text('Traffic & Zones', style: TextStyle(
            color: SafeRideTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: tColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('${controller.congestionPercent}%',
              style: TextStyle(color: tColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(controller.trafficReason.isEmpty ? 'Start tracking to detect traffic' : controller.trafficReason,
          style: const TextStyle(color: SafeRideTheme.textSecondary, fontSize: 13)),
        if (controller.nearbyPlaces.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: controller.nearbyPlaces.take(3).map((p) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SafeRideTheme.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text(p.name, style: const TextStyle(fontSize: 11, color: SafeRideTheme.accentPurple)),
            )).toList()),
        ],
      ]),
    );
  }

  Widget _buildLiveLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SafeRideTheme.glassCard(opacity: 0.06),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.location_on,
            color: controller.liveLocationSharing ? SafeRideTheme.neonGreen : SafeRideTheme.textSecondary, size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text('Live Location Sharing', style: TextStyle(
            color: SafeRideTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
          Switch(
            value: controller.liveLocationSharing,
            activeColor: SafeRideTheme.neonGreen,
            onChanged: (v) {
              if (v) { controller.startLiveLocationSharing(); }
              else { controller.stopLiveLocationSharing(); }
            },
          ),
        ]),
        const SizedBox(height: 6),
        Text(controller.liveLocationSharing
          ? 'Guardian can track you in real-time'
          : 'Enable to share location with guardian',
          style: const TextStyle(color: SafeRideTheme.textSecondary, fontSize: 12)),
        if (controller.liveTrackingLink.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SafeRideTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Text(controller.liveTrackingLink,
              style: const TextStyle(color: SafeRideTheme.neonGreen, fontSize: 11),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ]),
    );
  }

  Widget _buildRideAnalysis() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SafeRideTheme.glassCard(opacity: 0.06),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.analytics, color: SafeRideTheme.accentBlue, size: 22),
          SizedBox(width: 10),
          Text('AI Ride Analysis', style: TextStyle(
            color: SafeRideTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        const Text('Camera-based detection pipeline', style: TextStyle(color: SafeRideTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _analysisChip(Icons.sports_motorsports, 'Helmet', SafeRideTheme.warningOrange, controller.reportHelmetMissing),
          _analysisChip(Icons.traffic, 'Red Light', SafeRideTheme.dangerRed, controller.reportRedLightViolation),
          _analysisChip(Icons.directions_car, 'Traffic', SafeRideTheme.accentPurple, controller.reportHeavyTraffic),
        ]),
      ]),
    );
  }

  Widget _analysisChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: SafeRideTheme.glassCard(opacity: 0.06),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: SafeRideTheme.accentBlue,
          collapsedIconColor: SafeRideTheme.textSecondary,
          title: const Text('Settings', style: TextStyle(color: SafeRideTheme.textPrimary, fontWeight: FontWeight.w700)),
          subtitle: const Text('Guardian, Auto-On, Backend', style: TextStyle(color: SafeRideTheme.textSecondary, fontSize: 12)),
          children: [
            // Auto-On Toggle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: SafeRideTheme.accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.autorenew, color: SafeRideTheme.accentPurple, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text('Auto-On (detect driving)', style: TextStyle(color: SafeRideTheme.textPrimary, fontSize: 13))),
                Switch(value: controller.autoOnEnabled, activeColor: SafeRideTheme.accentPurple,
                  onChanged: (v) => controller.toggleAutoOn(v)),
              ]),
            ),
            TextField(controller: parentPhoneController,
              decoration: const InputDecoration(labelText: 'Guardian Phone', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone, style: const TextStyle(color: SafeRideTheme.textPrimary)),
            const SizedBox(height: 10),
            TextField(controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person)),
              style: const TextStyle(color: SafeRideTheme.textPrimary)),
            const SizedBox(height: 10),
            TextField(controller: destinationController,
              decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.flag)),
              style: const TextStyle(color: SafeRideTheme.textPrimary)),
            const SizedBox(height: 10),
            TextField(controller: backendUrlController,
              decoration: const InputDecoration(labelText: 'Backend URL', prefixIcon: Icon(Icons.cloud)),
              style: const TextStyle(color: SafeRideTheme.textPrimary)),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                await controller.saveSettings(
                  newParentPhone: parentPhoneController.text,
                  newBackendUrl: backendUrlController.text,
                  newUsername: usernameController.text,
                  newDestination: destinationController.text,
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved!')));
              },
              child: const Text('SAVE SETTINGS'),
            )),
          ],
        ),
      ),
    );
  }
}
