import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'narcan_instruction.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for mobile only
import 'package:path_provider/path_provider.dart' as path_provider;

class NarcanPrescriptionScreen extends StatefulWidget {
  const NarcanPrescriptionScreen({super.key});

  @override
  State<NarcanPrescriptionScreen> createState() => _NarcanPrescriptionScreenState();
}

class _NarcanPrescriptionScreenState extends State<NarcanPrescriptionScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await rootBundle.load('assets/150-127-StatewideStandingOrderToDispenseNaloxone.pdf');
      if (!kIsWeb) {
        final dir = await path_provider.getApplicationDocumentsDirectory();
        final file = File('${dir.path}/prescription.pdf');
        await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        setState(() {
          localPath = file.path;
        });
      }
    } catch (e) {
      // Handle error silently for web
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription PDF')),
      body: kIsWeb 
          ? _buildWebView()
          : _buildMobileView(),
    );
  }

  Widget _buildWebView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'PDF Viewer',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'PDF viewing is not available on web.\nPlease use the mobile app for full functionality.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.menu_book),
            label: const Text("View Narcan Instructions"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NarcanInstructionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView() {
    return localPath == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: PDFView(
                  filePath: localPath!,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.menu_book),
                  label: const Text("View Narcan Instructions"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NarcanInstructionScreen(),
                      ),
                    );
                  },
                ),
              )
            ],
          );
  }
}
