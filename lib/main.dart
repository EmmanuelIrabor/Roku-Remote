import 'package:flutter/material.dart';
import 'screens/discovery_screen.dart';

void main() {
  runApp(const RokuRemoteApp());
}

class RokuRemoteApp extends StatelessWidget {
  const RokuRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roku SSDP Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const DiscoveryScreen(),
    );
  }
}
