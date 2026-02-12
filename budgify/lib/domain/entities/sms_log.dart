import 'package:equatable/equatable.dart';

class SmsLog extends Equatable {
  final int? id;
  final String sender;
  final String body;
  final DateTime timestamp;

  const SmsLog({
    this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, sender, body, timestamp];
}
