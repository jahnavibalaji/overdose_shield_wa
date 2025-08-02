import 'package:flutter/material.dart';
import 'naloxone_map.dart';
import 'narcan_prescription.dart';
import 'narcan_instruction.dart';

void main() {
  runApp(const OverdoseShieldApp());
}

class OverdoseShieldApp extends StatelessWidget {
  const OverdoseShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overdose Shield WA',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const NaloxoneMapScreen(),
      routes: {
        '/narcan_prescription': (context) => const NarcanPrescriptionScreen(),
        '/narcan_instruction': (context) => const NarcanInstructionScreen(),
      },
    );
  }
}
