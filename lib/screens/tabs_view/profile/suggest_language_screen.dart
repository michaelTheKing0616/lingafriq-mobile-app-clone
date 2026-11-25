import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';
import 'package:lingafriq/widgets/titled_drop_down.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

class SuggestLanguageScreen extends HookConsumerWidget {
  const SuggestLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final suggestLanguageController = useTextEditingController(text: kDebugMode ? "Urdu" : null);
    // final reasonController = useTextEditingController(text: kDebugMode ? "Great language" : null);
    // final selectedCountry = useState<String?>(kDebugMode ? "Pakistan" : null);
    final suggestLanguageController = useTextEditingController();
    final reasonController = useTextEditingController();
    final selectedCountry = useState<String?>(null);

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ProfileImageBuilder(
            showEditIcon: false,
            size: Size(0.2.sw, 0.2.sw),
            onTap: null,
          ).centered(),
          24.heightBox,
          const ProfileDetailsBuilder(
            crossAxisAlignment: CrossAxisAlignment.center,
          ).centered(),
          48.heightBox,
          PrimaryTextField(
            controller: reasonController,
            title: l10nOf(context).shellWhatWouldYouLikeUsTo0de8,
            hintText: l10nOf(context).shellPleaseExplainWhatWouldYouLike,
            textInputAction: TextInputAction.done,
            minLines: 4,
            maxLines: 6,
          ),
          32.heightBox,
          PrimaryTextField(
            controller: suggestLanguageController,
            title: l10nOf(context).shellWouldYouLikeToSuggestAb06a,
            hintText: l10nOf(context).shellWriteYourSuggestionHere,
            textInputAction: TextInputAction.next,
            minLines: 2,
            maxLines: 3,
          ),
          32.heightBox,
          TitledDropDown<String>(
            title: l10nOf(context).shellLanguageCountry,
            titles: kCountries.keys.toList(),
            items: kCountries.keys.toList(),
            value: selectedCountry.value,
            onChanged: (value) => selectedCountry.value = value,
          ),
          48.heightBox,
          PanAfricanButton(
            width: 0.6.sw,
            onPressed: () {
              final suggestion = suggestLanguageController.text.trim();
              final reason = reasonController.text.trim();
              final country = selectedCountry.value;
              if (suggestion.isEmpty && reason.isEmpty) {
                VxToast.show(context, msg: l10nOf(context).shellPleaseFillInSomeFields);
                return;
              }
              String? encodeQueryParameters(Map<String, String> params) {
                return params.entries
                    .map((MapEntry<String, String> e) =>
                        '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                    .join('&');
              }

              var body = '';

              if (reason.isNotEmpty) {
                body += l10nOf(context).shellWhatWouldYouLikeUsTo(reason.toString());
              }

              if (suggestion.isNotEmpty) {
                body +=
                    l10nOf(context).shellWouldYouLikeToSuggestA(suggestion.toString());
              }
              if (country != null) {
                body += l10nOf(context).shellLanguageCountryCountry(country.toString());
              }

              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'lingafriq@gmail.com',
                query: encodeQueryParameters(<String, String>{
                  'subject': l10nOf(context).shellFeedbackFormOnMobileApp,
                  'body': body,
                }),
              );
              kLaunchUrl(emailLaunchUri.toString());
              // Navigator.of(context).pop();
            },
            label: l10nOf(context).shellSubmit,
          )
        ],
      ).px16().scrollVertical(),
    );
  }
}
