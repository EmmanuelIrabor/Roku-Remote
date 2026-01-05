import 'package:flutter/material.dart';
import '../services/roku_service.dart';

class RemoteScreen extends StatefulWidget {
  final String ipAddress;

  const RemoteScreen({super.key, required this.ipAddress});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  String lastCommand = '';
  bool isSending = false;

  final double buttonSizeMobile = 60;
  final double buttonSizeTablet = 90;

  Future<void> sendCommand(String command) async {
    setState(() {
      lastCommand = command;
      isSending = true;
    });

    final success = await RokuService.sendCommand(widget.ipAddress, command);

    setState(() {
      isSending = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send $command. Roku may not be reachable.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final buttonSize = isTablet ? buttonSizeTablet : buttonSizeMobile;

    return Scaffold(
      appBar: AppBar(
        title: Text('Roku Remote - ${widget.ipAddress}'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Up button
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                iconSize: buttonSize,
                onPressed: isSending ? null : () => sendCommand('Up'),
              ),
              const SizedBox(height: 16),

              // Left, Select, Right row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left),
                    iconSize: buttonSize,
                    onPressed: isSending ? null : () => sendCommand('Left'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isSending ? null : () => sendCommand('Select'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(buttonSize, buttonSize),
                      shape: const CircleBorder(),
                    ),
                    child: const Text('OK'),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right),
                    iconSize: buttonSize,
                    onPressed: isSending ? null : () => sendCommand('Right'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Down button
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                iconSize: buttonSize,
                onPressed: isSending ? null : () => sendCommand('Down'),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: isSending ? null : () => sendCommand('Back'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: isSending ? null : () => sendCommand('Home'),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Play/Pause controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fast_rewind),
                    iconSize: buttonSize * 0.8,
                    onPressed: isSending ? null : () => sendCommand('Rev'),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    iconSize: buttonSize * 0.8,
                    onPressed: isSending ? null : () => sendCommand('Play'),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.fast_forward),
                    iconSize: buttonSize * 0.8,
                    onPressed: isSending ? null : () => sendCommand('Fwd'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Last command display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lastCommand.isEmpty
                      ? 'Send a command...'
                      : 'Last command: $lastCommand',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
