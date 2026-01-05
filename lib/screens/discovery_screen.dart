import 'package:flutter/material.dart';
import '../services/roku_service.dart';
import 'remote_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  String _statusText = '';
  List<RokuDevice> _foundDevices = [];
  bool _isDiscovering = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final padding = isTablet ? 32.0 : 16.0;
    final contentWidth = isTablet ? 600.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Roku Discovery'), centerTitle: true),
      body: Center(
        child: Container(
          width: contentWidth,
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isDiscovering
                    ? null
                    : () async {
                        setState(() {
                          _isDiscovering = true;
                          _statusText = 'Discovering devices...';
                          _foundDevices = [];
                        });

                        final devices = await RokuService.discoverDevices(
                          useMock: false,
                        );

                        setState(() {
                          _foundDevices = devices;
                          _isDiscovering = false;
                          _statusText = devices.isEmpty
                              ? 'No devices found. Make sure you\'re on the same WiFi network as your Roku.'
                              : '';
                        });
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _isDiscovering ? 'Discovering...' : 'Discover Roku Devices',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (_statusText.isNotEmpty)
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),

              const SizedBox(height: 24),

              // List discovered devices
              if (_foundDevices.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _foundDevices.length,
                    itemBuilder: (context, index) {
                      final device = _foundDevices[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.tv, size: 40),
                          title: Text(device.name),
                          subtitle: Text(device.ip),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RemoteScreen(ipAddress: device.ip),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
