import 'package:flutter/material.dart';

import '../../../models/language_response.dart';
import 'home_tab.dart';

class SearchLanguageDelegate extends SearchDelegate {
  final List<Language> languages;

  SearchLanguageDelegate(this.languages);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return BackButton(
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchedLanguages = query.isEmpty
        ? languages
        : languages
            .where((element) => element.toJson().toLowerCase().contains(query.toLowerCase()))
            .toList();
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: searchedLanguages
          .map((e) => LanguageItem(
                language: e,
                onTap: () async {
                  close(context, null);
                },
              ))
          .toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final searchedLanguages = query.isEmpty
        ? languages
        : languages
            .where((element) => element.toJson().toLowerCase().contains(query.toLowerCase()))
            .toList();
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: searchedLanguages
          .map((e) => LanguageItem(
                language: e,
                onTap: () {
                  close(context, null);
                },
              ))
          .toList(),
    );
  }
}
