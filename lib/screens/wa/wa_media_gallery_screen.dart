import 'package:flutter/material.dart';
import 'package:lingafriq/screens/wa/ui/wa_theme.dart';

class WaMediaGalleryScreen extends StatelessWidget {
  const WaMediaGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = List.generate(12, (i) => i);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: WaUi.scaffoldBg(isDark),
        appBar: AppBar(
          backgroundColor: WaUi.scaffoldBg(isDark),
          title: const Text('Media gallery'),
          bottom: const TabBar(tabs: [Tab(text: 'Media'), Tab(text: 'Links'), Tab(text: 'Docs')]),
        ),
        body: TabBarView(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: media.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(
                  color: WaUi.cardBg(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(i % 3 == 0 ? Icons.play_circle_outline : Icons.image_outlined),
              ),
            ),
            ListView(
              children: const [
                ListTile(title: Text('yoruba-grammar-guide.org'), subtitle: Text('Shared 2 days ago')),
                ListTile(title: Text('african-languages.blog'), subtitle: Text('Shared 1 week ago')),
              ],
            ),
            ListView(
              children: const [
                ListTile(leading: Icon(Icons.description_outlined), title: Text('Lesson Notes.pdf'), subtitle: Text('220 KB')),
                ListTile(leading: Icon(Icons.description_outlined), title: Text('Phrase Checklist.docx'), subtitle: Text('78 KB')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
