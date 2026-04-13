import 'package:flutter/material.dart';

/// One-tap access to **named routes** that map Stitch mockup journeys (Phase 0–4 program).
/// Deep links: `Navigator.pushNamed(context, '/stitch-hub')` or route name `stitch-hub`.
class StitchNavigationHubScreen extends StatelessWidget {
  const StitchNavigationHubScreen({super.key});

  static const _sections = <_HubSection>[
    _HubSection(
      title: 'FLB · magazine · heritage · import',
      routes: [
        _HubRoute('Magazine & discovery', 'magazine'),
        _HubRoute('FLB heritage archive', 'flb-heritage-archive'),
        _HubRoute('Import / studio media', 'import_media'),
        _HubRoute('UGC hub', 'ugc'),
        _HubRoute('Vocabulary / glossary', 'vocabulary-builder'),
      ],
    ),
    _HubSection(
      title: 'Community · chat · classroom',
      routes: [
        _HubRoute('Community feed (X)', 'x-feed-home'),
        _HubRoute('Explore community', 'explore-community'),
        _HubRoute('Search community', 'search-community'),
        _HubRoute('Community profile', 'community-profile'),
        _HubRoute('Global chat', 'global_chat'),
        _HubRoute('Private chat inbox', 'private-chat-inbox'),
        _HubRoute('Call history', 'call-history'),
        _HubRoute('Live classroom', 'live-classroom'),
        _HubRoute('Classroom lobby (tribes)', 'classroom-lobby'),
        _HubRoute('Classroom notes', 'classroom-notes'),
        _HubRoute('Speaker queue', 'speaker-queue'),
      ],
    ),
    _HubSection(
      title: 'Villages · tribes · practice',
      routes: [
        _HubRoute('Villages hub', 'villages-hub'),
        _HubRoute('Language villages', 'language-village'),
        _HubRoute('Swahili village map', 'swahili-village-map'),
        _HubRoute('Tribe hub', 'tribe-hub'),
        _HubRoute('Tribe discovery', 'tribe-discovery'),
        _HubRoute('My tribe', 'my-tribe'),
        _HubRoute('Practice session', 'practice-session'),
      ],
    ),
    _HubSection(
      title: 'Games (speed round cluster)',
      routes: [
        _HubRoute('Games hub (Material 3)', 'games'),
        _HubRoute('Games · API language list', 'games_api_languages'),
        _HubRoute('Games · enhanced static catalog', 'games_enhanced_catalog'),
      ],
    ),
    _HubSection(
      title: 'WhatsApp / Snap upgrades',
      routes: [
        _HubRoute('WA status', 'wa-status'),
        _HubRoute('WA starred', 'wa-starred'),
        _HubRoute('Snap inbox', 'snap-inbox'),
        _HubRoute('Snap story feed', 'snap-story-feed'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stitch feature map'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        itemBuilder: (context, i) {
          final s = _sections[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              initiallyExpanded: i == 0,
              children: s.routes
                  .map(
                    (r) => ListTile(
                      title: Text(r.label),
                      subtitle: Text('/${r.name}', style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(context).pushNamed('/${r.name}');
                      },
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _HubSection {
  const _HubSection({required this.title, required this.routes});
  final String title;
  final List<_HubRoute> routes;
}

class _HubRoute {
  const _HubRoute(this.label, this.name);
  final String label;
  final String name;
}
