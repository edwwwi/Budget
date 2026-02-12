class SmsLogModel {
  final int? id;
  final String sender;
  final String body;
  final DateTime timestamp;

  SmsLogModel({
    this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SmsLogModel.fromMap(Map<String, dynamic> map) {
    return SmsLogModel(
      id: map['id'],
      sender: map['sender'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
