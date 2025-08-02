import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NaloxoneMapScreen extends StatelessWidget {
  const NaloxoneMapScreen({super.key});

  Future<void> _openMaps(BuildContext context) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=pharmacies+near+me',
    );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch Google Maps.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open a maps app. Please make sure one is installed.'),
        ),
      );
    }
  }

  void _showReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminder'),
        content: const Text(
          'After finding a pharmacy, return to the app to view the Narcan prescription and instructions.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openMaps(context);
            },
            child: const Text('Open Maps'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _goToPrescription(BuildContext context) {
    Navigator.pushNamed(context, '/narcan_prescription');
  }

  void _goToInstructions(BuildContext context) {
    Navigator.pushNamed(context, '/narcan_instruction');
  }

  Future<void> _callEmergency(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '5124158065');

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the dialer.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overdose Shield WA'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showReminder(context),
                icon: const Icon(Icons.map),
                label: const Text('Search Nearby Pharmacies'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _goToPrescription(context),
                icon: const Icon(Icons.description),
                label: const Text('View Narcan Prescription'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _goToInstructions(context),
                icon: const Icon(Icons.info),
                label: const Text('View Narcan Instructions'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _callEmergency(context),
                icon: const Icon(Icons.phone),
                label: const Text('Emergency Help'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
