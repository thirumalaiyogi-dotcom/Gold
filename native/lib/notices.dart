import 'package:flutter/material.dart';

import 'main.dart';
import 'notify.dart';
import 'ui.dart';

/// அறிவிப்பு tab — live notices from the shop (gold_notices).
class NoticesTab extends StatelessWidget {
  const NoticesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([app, Notify.readBefore]),
      builder: (context, _) => SafeArea(
        child: RefreshIndicator(
          color: C.navy,
          onRefresh: app.loadPublic,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
            Text('அறிவிப்புகள்', style: serif(22, color: C.ink, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (!app.noticesLoaded)
              const SkeletonList(count: 3)
            else if (app.notices.isEmpty)
              Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('இப்போதைக்கு புது அறிவிப்பு எதுவும் இல்லை.', style: sans(14, color: C.mute))))
            else
              for (final n in app.notices)
                Builder(builder: (context) {
                  final rb = Notify.readBefore.value;
                  final isNew = rb.isNotEmpty && '${n['created_at'] ?? ''}'.compareTo(rb) > 0;
                  return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNew ? const Color(0xFFFFFDF8) : C.paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isNew ? C.gold : C.line2, width: isNew ? 1.4 : 1),
                    boxShadow: const [BoxShadow(color: Color(0x0D4A0D18), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (isNew)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(99)),
                        child: Text('புதுசு', style: sans(11.5, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text((n['title'] ?? '').toString(), style: sans(15.5, color: C.head, weight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      Text(taDate((n['created_at'] ?? '').toString()), style: sans(12, color: C.mute)),
                    ]),
                    if ((n['body'] ?? '').toString().trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(n['body'].toString(), style: sans(14, height: 1.6)),
                    ],
                  ]),
                );
                }),
          ]),
        ),
      ),
    );
  }
}
