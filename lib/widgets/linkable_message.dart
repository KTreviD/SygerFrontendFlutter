import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/handle_whatsapp_link.dart';
import '../constants/colors.dart';

class LinkableMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const LinkableMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'((http|https):\/\/[^\s]+)');
    final spans = <TextSpan>[];

    text.splitMapJoin(
      regex,
      onMatch: (match) {
        final url = match.group(0)!;
        spans.add(
          TextSpan(
            text: url,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () async {
                    if (url.contains('https://wa.me/')) {
                      await handleWhatsAppLink(url);
                    } else if (await canLaunch(url)) {
                      await launch(url);
                    } else {
                      throw 'No se pudo abrir el enlace: $url';
                    }
                  },
          ),
        );
        return '';
      },
      onNonMatch: (nonMatch) {
        spans.add(
          TextSpan(
            text: nonMatch,
            style: TextStyle(color: isUser ? Colors.white : Colors.black87),
          ),
        );
        return '';
      },
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryApp : AppColors.backgroundMessage,
          borderRadius: BorderRadius.circular(12),
          border: isUser ? Border.all(color: Colors.grey) : null,
        ),
        child: SelectableText.rich(TextSpan(children: spans)),
      ),
    );
  }
}
