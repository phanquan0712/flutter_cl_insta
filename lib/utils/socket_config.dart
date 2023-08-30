import 'package:insta_node_app/recources/repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketConfig {
  static IO.Socket socket = IO.io(
      Repository.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .disableAutoConnect() // disable auto-connection
          .build());

  // joinuser
  static void joinUser(dynamic user) {
    socket.emit('joinUser', user);
  }

  // create message
  static void createMessage(dynamic message) {
    socket.emit('addMessage', message);
  }

  // create comment
  static void createComment(dynamic comment) {
    socket.emit('createComment', comment);
  }

  // create notify
  static void createNotify(dynamic notify) {
    socket.emit('createNotify', notify);
  }

  // delete notify
  static void deleteNotify(dynamic notify) {
    socket.emit('deleteNotify', notify);
  }

  // checkUserOnline
  static void checkUserOnline(dynamic user) {
    socket.emit('checkUserOnline', user);
  }

  // call user
  static void callUser(dynamic call) {
    socket.emit('callUser', call);
  }

  // end call user
  static void endCall(dynamic call) {
    socket.emit('endCall', call);
  }
}
