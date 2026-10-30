import 'package:flutter/material.dart';
import 'package:lingafriq/theme/lingafriq_fonts.dart';
import 'package:lingafriq/data/polie_translate_language_options.dart';

/// Searchable bottom sheet for FLORES / NLLB language selection.
class PolieLanguageSearchSheet extends StatefulWidget {
  const PolieLanguageSearchSheet({
    super.key,
    required this.title,
    required this.selectedDisplayName,
    required this.onSelected,
  });

  final String title;
  final String selectedDisplayName;
  final void Function(PolieTranslateLanguageOption) onSelected;

  @override
  State<PolieLanguageSearchSheet> createState() =>
      PolieLanguageSearchSheetState();
}

class PolieLanguageSearchSheetState extends State<PolieLanguageSearchSheet> {
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    _query = TextEditingController();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final q = _query.text.trim().toLowerCase();
    final filtered = kPolieTranslateLanguageOptions.where((o) {
      if (q.isEmpty) return true;
      return o.displayName.toLowerCase().contains(q) ||
          o.backendKey.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: LingAfriqFonts.roleStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _query,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or code (e.g. yor_Latn)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final o = filtered[index];
                      final sel = o.displayName == widget.selectedDisplayName;
                      return ListTile(
                        selected: sel,
                        title: Text(
                          o.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          o.backendKey,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          widget.onSelected(o);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
