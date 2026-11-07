import 'package:flutter/material.dart';

import 'data.dart';
import 'ui.dart';

/// அறிவிப்பு tab.
class NoticesTab extends StatelessWidget {
  const NoticesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
        Text('அறிவிப்புகள்', style: serif(22, color: C.ink, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF6EEDC), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.goldLine)),
          child: Row(children: [
            const Icon(Icons.notifications_active_outlined, color: C.navy),
            const SizedBox(width: 12),
            Expanded(child: Text('தவணை நினைவூட்டல், விலை மாற்றம், சலுகைகள் phone-க்கே வர Notification-ஐ ON பண்ணுங்க.', style: sans(13.5, height: 1.55))),
          ]),
        ),
        const SizedBox(height: 14),
        if (notices.isEmpty)
          Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('இப்போதைக்கு புது அறிவிப்பு எதுவும் இல்லை.', style: sans(14, color: C.mute))))
        else
          for (final n in notices)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line2)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n.title, style: sans(15.5, weight: FontWeight.w700))),
                  Text(n.date, style: sans(12, color: C.mute)),
                ]),
                const SizedBox(height: 6),
                Text(n.body, style: sans(14, height: 1.6)),
              ]),
            ),
      ]),
    );
  }
}
