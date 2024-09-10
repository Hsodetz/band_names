
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:socket_io_client/socket_io_client.dart';

enum ServerStatus {
  online,
  offline,
  connecting,
}

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.connecting;
  late IO.Socket _socket;

  ServerStatus get serverStatus => _serverStatus;
  IO.Socket get socket => _socket;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    // Dart client
    _socket = IO.io('http://192.168.100.6:3000',
      OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .enableAutoConnect()  // enabled auto-connection
      //.setExtraHeaders({'foo': 'bar'}) // optional
      .build()
    );
    _socket.onConnect((_) {
      _serverStatus = ServerStatus.online;
      notifyListeners();
    });
    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.offline;
      notifyListeners();
    });

    _socket.on('newMessage', (data) {
      print('newMessage: $data');
    });
  }

}