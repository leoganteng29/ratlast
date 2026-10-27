import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';

// ⚠️ GANTI URL DAN UID INI ⚠️
const String SERVER_URL = 'http://152.42.184.64:2363'; 
const String TARGET_UID = 'd7e27df25f68d737f7a454b58a97f77c'; 

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
      .enableAutoConnect()
      .setReconnectionAttempts(10) // Biar terus nyoba konek
      .setReconnectionDelay(2000)
      .build()
    );

    socket.onConnect((_) {
      print('KONEK!');
      // 🔥 KUNCI: Sesuaikan nama event dengan yang ada di sync.js
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

    socket.onConnectError((err) {
      print('GAGAL KONEK: $err');
    });

    socket.onError((err) {
      print('ERROR: $err');
    });
    
  } catch (e) {
    print('Error: $e');
  }
}
