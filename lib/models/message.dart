class Message {
  final int? userId;
  final bool isUser;
  final String message;
  final int? messageTypeId;

  Message(this.userId, this.isUser, this.message, this.messageTypeId);

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      int.tryParse(json['user_id'].toString()),
      json['is_user'] == true || json['is_user'] == 1,
      json['message'] as String,
      int.tryParse(json['message_type_id'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_user': isUser,
      'message': message,
      'message_type_id': messageTypeId,
    };
  }
}
