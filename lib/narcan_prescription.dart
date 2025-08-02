import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'narcan_instruction.dart';

class NarcanPrescriptionScreen extends StatefulWidget {
  const NarcanPrescriptionScreen({Key? key}) : super(key: key);

  @override
  State<NarcanPrescriptionScreen> createState() => _NarcanPrescriptionScreenState();
}

class _NarcanPrescriptionScreenState extends State<NarcanPrescriptionScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final bytes = await rootBundle.load('assets/150-127-StatewideStandingOrderToDispenseNaloxone.pdf');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/prescription.pdf');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    setState(() {
      localPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription PDF')),
      body: localPath == null
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
      ),
    );
  }
}
