import 'package:flutter/material.dart';

import '../map/map_screen.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;
  late final TextEditingController parentPhoneController;
  late final TextEditingController backendUrlController;
  late final TextEditingController usernameController;
  late final TextEditingController destinationController;

  @override
  void initState() {
    super.initState();
    controller = HomeController()..addListener(_refresh);
    parentPhoneController = TextEditingController();
    backendUrlController = TextEditingController();
    usernameController = TextEditingController();
    destinationController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    await controller.loadSettings();
    parentPhoneController.text = controller.parentPhone;
    backendUrlController.text = controller.backendUrl;
    usernameController.text = controller.username;
    destinationController.text = controller.destination;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    parentPhoneController.dispose();
    backendUrlController.dispose();
    usernameController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overspeed = controller.speedKmh > controller.speedLimitKmh;
    final hasLocation = controller.latitude != 0 || controller.longitude != 0;
    final guardianReady = controller.parentPhone.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                tracking: controller.tracking,
                guardianReady: guardianReady,
                onMapTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MapScreen(
                        latitude: controller.latitude,
                        longitude: controller.longitude,
                        routeSamples: controller.routeSamples,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SpeedHero(
                speedKmh: controller.speedKmh,
                overspeed: overspeed,
                tracking: controller.tracking,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.location_on_outlined,
                      label: 'GPS',
                      value: hasLocation ? 'Locked' : 'Waiting',
                      subtitle: hasLocation
                          ? '${controller.latitude.toStringAsFixed(4)}, ${controller.longitude.toStringAsFixed(4)}'
                          : 'Need outdoor signal',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.vibration,
                      label: 'Impact',
                      value: '${controller.impactG.toStringAsFixed(2)} g',
                      subtitle: 'Live sensor feed',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (controller.accidentSuspicion) ...[
                _AccidentAlertCard(
                  countdown: controller.countdown,
                  onSafe: controller.markSafe,
                  onConfirm: controller.confirmAccidentNow,
                ),
                const SizedBox(height: 14),
              ],
              _ActionRow(
                tracking: controller.tracking,
                onTrackingTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (controller.tracking) {
                    await controller.stopTracking();
                    return;
                  }

                  final started = await controller.startTracking();
                  if (!started && mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Location permission is required'),
                      ),
                    );
                  }
                },
                onSosTap: controller.manualSos,
              ),
              const SizedBox(height: 14),
              _RideAnalysisCard(
                onHelmetMissing: controller.reportHelmetMissing,
                onRedLight: controller.reportRedLightViolation,
                onHeavyTraffic: controller.reportHeavyTraffic,
              ),
              const SizedBox(height: 14),
              _SettingsCard(
                parentPhoneController: parentPhoneController,
                backendUrlController: backendUrlController,
                usernameController: usernameController,
                destinationController: destinationController,
                onSave: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await controller.saveSettings(
                    newParentPhone: parentPhoneController.text,
                    newBackendUrl: backendUrlController.text,
                  newUsername: usernameController.text,
                  newDestination: destinationController.text,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tracking,
    required this.guardianReady,
    required this.onMapTap,
  });

  final bool tracking;
  final bool guardianReady;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SafeRide Guardian',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: tracking ? 'Tracking active' : 'Tracking off',
                    color: tracking ? Colors.green : Colors.grey,
                  ),
                  _StatusChip(
                    label: guardianReady ? 'Guardian ready' : 'Guardian missing',
                    color: guardianReady ? Colors.blue : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onMapTap,
          icon: const Icon(Icons.map_outlined),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpeedHero extends StatelessWidget {
  const _SpeedHero({
    required this.speedKmh,
    required this.overspeed,
    required this.tracking,
  });

  final double speedKmh;
  final bool overspeed;
  final bool tracking;

  @override
  Widget build(BuildContext context) {
    final accent = overspeed ? Colors.red : const Color(0xFF146C94);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            tracking ? 'Current ride speed' : 'Ready to track',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            speedKmh.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF10233A),
                ),
          ),
          Text(
            'km/h',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            overspeed ? 'Overspeed warning — slow down' : 'Speed is within safe range',
            style: TextStyle(
              color: overspeed ? Colors.red.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.tracking,
    required this.onTrackingTap,
    required this.onSosTap,
  });

  final bool tracking;
  final VoidCallback onTrackingTap;
  final VoidCallback onSosTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onTrackingTap,
            icon: Icon(tracking ? Icons.stop_circle_outlined : Icons.play_circle_outline),
            label: Text(tracking ? 'Stop Tracking' : 'Start Tracking'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: onSosTap,
            icon: const Icon(Icons.sos),
            label: const Text('Manual SOS'),
          ),
        ),
      ],
    );
  }
}

class _AccidentAlertCard extends StatelessWidget {
  const _AccidentAlertCard({
    required this.countdown,
    required this.onSafe,
    required this.onConfirm,
  });

  final int countdown;
  final VoidCallback onSafe;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accident-like event detected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Guardian alert in $countdown seconds'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSafe,
                  child: const Text('I am safe'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: onConfirm,
                  child: const Text('Alert now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.parentPhoneController,
    required this.backendUrlController,
    required this.usernameController,
    required this.destinationController,
    required this.onSave,
  });

  final TextEditingController parentPhoneController;
  final TextEditingController backendUrlController;
  final TextEditingController usernameController;
  final TextEditingController destinationController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: const Text(
          'Emergency Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Guardian, account, and backend connection'),
        children: [
          TextField(
            controller: parentPhoneController,
            decoration: const InputDecoration(labelText: 'Parent/Guardian phone'),
            keyboardType: TextInputType.phone,
          ),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: destinationController,
            decoration: const InputDecoration(labelText: 'Destination'),
          ),
          TextField(
            controller: backendUrlController,
            decoration: const InputDecoration(labelText: 'Django backend URL'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideAnalysisCard extends StatelessWidget {
  const _RideAnalysisCard({
    required this.onHelmetMissing,
    required this.onRedLight,
    required this.onHeavyTraffic,
  });

  final VoidCallback onHelmetMissing;
  final VoidCallback onRedLight;
  final VoidCallback onHeavyTraffic;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('AI-ready ride events. These buttons test the full safety pipeline until a real camera model is connected.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onHelmetMissing,
                  icon: const Icon(Icons.sports_motorsports_outlined),
                  label: const Text('Helmet missing'),
                ),
                OutlinedButton.icon(
                  onPressed: onRedLight,
                  icon: const Icon(Icons.traffic_outlined),
                  label: const Text('Red-light event'),
                ),
                OutlinedButton.icon(
                  onPressed: onHeavyTraffic,
                  icon: const Icon(Icons.directions_car_filled_outlined),
                  label: const Text('Heavy traffic'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

