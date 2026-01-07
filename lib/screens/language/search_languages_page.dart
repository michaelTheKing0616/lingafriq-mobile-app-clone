import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../utils/pan_african_design_system.dart';
import '../../services/localization/dynamic_localization_service.dart';
import '../../widgets/pan_african_app_bar.dart';

/// Search Languages Page - Allows users to search and select languages
class SearchLanguagesPage extends HookConsumerWidget {
  const SearchLanguagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');
    final availableLanguages = AppLanguage.values;

    final filteredLanguages = availableLanguages.where((lang) {
      if (searchQuery.value.isEmpty) return true;
      return lang.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          lang.displayName.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: PanAfricanAppBar(
        title: 'Search Languages',
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search languages...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                ),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                final language = filteredLanguages[index];
                return ListTile(
                  title: Text(language.displayName),
                  subtitle: Text(language.code),
                  onTap: () {
                    Navigator.pop(context, language);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

