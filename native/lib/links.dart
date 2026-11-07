import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui.dart';

/// Shop contact links (same numbers / address as the website).
class Shop {
  static const phone1 = '+919791918344';
  static const phone2 = '+919344395078';
  static const waNumber = '919791918344';
  static const maps = 'https://www.google.com/maps/search/?api=1&query=51b+Gangai+Amman+Kovil+St+Gandhi+Bazar+Puliyangudi+627855';
  static const privacy = 'https://gold.thirumalaiyogi.workers.dev/privacy.html';
}

Future<void> openLink(BuildContext context, String url) async {
  tapFeel();
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) showNote(context, 'திறக்க முடியல', ok: false);
}

Future<void> callShop(BuildContext context, [String phone = Shop.phone1]) => openLink(context, 'tel:$phone');

Future<void> whatsApp(BuildContext context, [String text = 'வணக்கம், தங்க சேமிப்புத் திட்டம் பற்றி விபரம் வேண்டும்.']) =>
    openLink(context, 'https://api.whatsapp.com/send?phone=${Shop.waNumber}&text=${Uri.encodeComponent(text)}');

Future<void> openMaps(BuildContext context) => openLink(context, Shop.maps);
