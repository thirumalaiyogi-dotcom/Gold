import 'package:flutter/material.dart';

import 'main.dart';
import 'ui.dart';

/// அறிவிப்பு tab — live notices from the shop (gold_notices).
class NoticesTab extends StatelessWidget {
  const NoticesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => SafeArea(
        child: RefreshIndicator(
          color: C.navy,
          onRefresh: app.loadPublic,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
            Text('அறிவிப்புகள்', style: serif(22, color: C.ink, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (!app.noticesLoaded)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: C.navy)))
            else if (app.notices.isEmpty)
              Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('இப்போதைக்கு புது அறிவிப்பு எதுவும் இல்லை.', style: sans(14, color: C.mute))))
            else
              for (final n in app.notices)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line2)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text((n['title'] ?? '').toString(), style: sans(15.5, weight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      Text(taDate((n['created_at'] ?? '').toString()), style: sans(12, color: C.mute)),
                    ]),
                    if ((n['body'] ?? '').toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(n['body'].toString(), style: sans(14, height: 1.6)),
                    ],
                  ]),
                ),
          ]),
        ),
      ),
    );
  }
}
