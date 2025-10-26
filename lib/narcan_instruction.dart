import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NarcanInstructionScreen extends StatefulWidget {
  const NarcanInstructionScreen({super.key});

  @override
  State<NarcanInstructionScreen> createState() => _NarcanInstructionScreenState();
}

class _NarcanInstructionScreenState extends State<NarcanInstructionScreen> {
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
      final bytes = await rootBundle.load('assets/narcan_access_instructions.pdf');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/instructions.pdf');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      setState(() {
        localPath = file.path;
      });
    } catch (e) {
      // Handle error silently for web
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Narcan Instructions'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: kIsWeb 
          ? _buildWebView()
          : _buildMobileView(),
    );
  }

  Widget _buildWebView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Narcan Instructions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'PDF viewing is not available on web.\nPlease use the mobile app for full functionality.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView() {
    return localPath == null
        ? const Center(child: CircularProgressIndicator())
        : PDFView(filePath: localPath!);
  }
}
