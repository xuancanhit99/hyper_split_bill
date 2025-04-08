import 'package:injectable/injectable.dart';

abstract class ChatDataSource {
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? modelName,
  });
}
