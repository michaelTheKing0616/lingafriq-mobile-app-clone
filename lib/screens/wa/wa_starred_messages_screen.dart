import 'package:flutter/material.dart';
import 'package:lingafriq/screens/wa/ui/wa_theme.dart';

class WaStarredMessagesScreen extends StatelessWidget {
  const WaStarredMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = const [
      ('Amina', 'Great tip: pronounce tone with breath control.', '09:31'),
      ('Kwesi', 'Let us practice past tense after class.', 'Yesterday'),
      ('Lina', 'This phrase is useful in market conversations.', 'Mon'),
    ];

    return Scaffold(
      backgroundColor: WaUi.scaffoldBg(isDark),
      appBar: AppBar(
        backgroundColor: WaUi.scaffoldBg(isDark),
        title: const Text('Starred messages'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WaUi.cardBg(isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star, color: WaUi.primary()),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(item.$2),
                    ],
                  ),
                ),
                Text(item.$3, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
