class Message {
  final String text;
  final bool isUser;
  final List<String>? options;

  Message(this.text, this.isUser, {this.options});
}
