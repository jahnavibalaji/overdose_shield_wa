import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NarcanInstructionScreen extends StatefulWidget {
  const NarcanInstructionScreen({Key? key}) : super(key: key);

  @override
  State<NarcanInstructionScreen> createState() => _NarcanInstructionScreenState();
}

class _NarcanInstructionScreenState extends State<NarcanInstructionScreen> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final bytes = await rootBundle.load('assets/narcan_access_instructions.pdf');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/instructions.pdf');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    setState(() {
      localPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Narcan Instructions')),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(filePath: localPath!),
    );
  }
}
