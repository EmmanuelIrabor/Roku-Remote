import 'dart:async';
import 'dart:io';
import 'dart:convert';

class RokuDevice {
  final String name;
  final String ip;

  RokuDevice({required this.name, required this.ip});
}

class RokuService {
  static const String _ssdpAddress = '239.255.255.250';
  static const int _ssdpPort = 1900;
  static const Duration _timeout = Duration(seconds: 5);

  static Future<List<RokuDevice>> discoverDevices({
    bool useMock = false,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 2));
      return [
        RokuDevice(name: 'Roku Living Room', ip: '192.168.1.23'),
        RokuDevice(name: 'Roku Bedroom', ip: '192.168.1.24'),
      ];
    }

    List<RokuDevice> devices = [];
    RawDatagramSocket? socket;

    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        reusePort: true,
      );

      socket.broadcastEnabled = true;
      socket.multicastLoopback = false;
      socket.joinMulticast(InternetAddress(_ssdpAddress));

      final searchRequest =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: $_ssdpAddress:$_ssdpPort\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 3\r\n'
          'ST: roku:ecp\r\n'
          '\r\n';

      socket.send(
        searchRequest.codeUnits,
        InternetAddress(_ssdpAddress),
        _ssdpPort,
      );

      final completer = Completer<List<RokuDevice>>();
      final foundIps = <String>{};

      Timer(_timeout, () {
        if (!completer.isCompleted) {
          completer.complete(devices);
          socket?.close();
        }
      });

      socket.listen((event) async {
        if (event == RawSocketEvent.read) {
          final datagram = socket!.receive();
          if (datagram != null) {
            final msg = String.fromCharCodes(datagram.data);
            final ip = datagram.address.address;

            if (msg.contains('roku:ecp') && !foundIps.contains(ip)) {
              foundIps.add(ip);

              final locationMatch = RegExp(
                r'LOCATION:\s*(.+)',
                caseSensitive: false,
              ).firstMatch(msg);

              if (locationMatch != null) {
                try {
                  final name = await _fetchDeviceName(ip);
                  devices.add(RokuDevice(name: name, ip: ip));
                } catch (e) {
                  print('Error fetching device name for $ip: $e');

                  devices.add(RokuDevice(name: 'Roku Device', ip: ip));
                }
              }
            }
          }
        }
      });

      return completer.future;
    } catch (e) {
      print('SSDP Discovery error: $e');
      return [];
    } finally {
      socket?.close();
    }
  }

  static Future<String> _fetchDeviceName(String ip) async {
    final url = Uri.parse('http://$ip:8060/');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        client.close();

        // Parse XML response to get friendlyName
        final nameMatch = RegExp(
          r'<friendlyName>(.*?)<\/friendlyName>',
          dotAll: true,
        ).firstMatch(body);

        return nameMatch?.group(1)?.trim() ?? 'Roku Device';
      }

      client.close();
      return 'Roku Device';
    } catch (e) {
      print('Error fetching device name from $ip: $e');
      return 'Roku Device';
    }
  }

  static Future<bool> sendCommand(String ip, String command) async {
    final url = Uri.parse('http://$ip:8060/keypress/$command');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      final request = await client.postUrl(url);
      final response = await request.close();

      final success = response.statusCode == 200 || response.statusCode == 201;

      client.close();
      return success;
    } catch (e) {
      print('Error sending command $command to $ip: $e');
      return false;
    }
  }

  /// Get list of installed apps on a Roku device
  static Future<List<Map<String, String>>> getInstalledApps(String ip) async {
    final url = Uri.parse('http://$ip:8060/query/apps');
    List<Map<String, String>> apps = [];

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        client.close();

        // Parse XML to extract app info
        final appMatches = RegExp(
          r'<app id="(\d+)"[^>]*>(.*?)<\/app>',
          dotAll: true,
        ).allMatches(body);

        for (final match in appMatches) {
          apps.add({'id': match.group(1) ?? '', 'name': match.group(2) ?? ''});
        }
      } else {
        client.close();
      }

      return apps;
    } catch (e) {
      print('Error fetching apps from $ip: $e');
      return [];
    }
  }

  /// Launch an app on a Roku device
  static Future<bool> launchApp(String ip, String appId) async {
    final url = Uri.parse('http://$ip:8060/launch/$appId');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);

      final request = await client.postUrl(url);
      final response = await request.close();

      final success = response.statusCode == 200 || response.statusCode == 201;

      client.close();
      return success;
    } catch (e) {
      print('Error launching app $appId on $ip: $e');
      return false;
    }
  }
}
