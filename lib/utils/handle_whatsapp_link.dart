import 'package:url_launcher/url_launcher.dart';

Future<void> handleWhatsAppLink(String link) async {
  final regex = RegExp(r'https:\/\/wa\.me\/(\d+)');
  final match = regex.firstMatch(link);

  if (match != null) {
    final phone = match.group(1);
    final fixedUrl = 'https://api.whatsapp.com/send/?phone=$phone';

    if (await canLaunchUrl(fixedUrl as Uri)) {
      await launchUrl(fixedUrl as Uri);
    } else {
      throw 'No se pudo abrir el enlace: $fixedUrl';
    }
  } else {
    throw 'El enlace no es válido para WhatsApp.';
  }
}
