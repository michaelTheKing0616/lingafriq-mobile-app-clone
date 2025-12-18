import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/widgets/primary_text_field.dart';
import 'package:lingafriq/widgets/titled_drop_down.dart';

class SuggestLanguageScreen extends HookConsumerWidget {
  const SuggestLanguageScreen({Key? key}) : super(key: key);

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
            onTap: () {},
          ).centered(),
          24.heightBox,
          const ProfileDetailsBuilder(
            crossAxisAlignment: CrossAxisAlignment.center,
          ).centered(),
          48.heightBox,
          PrimaryTextField(
            controller: reasonController,
            title: "What would you like us to know?",
            hintText: "Please explain What would you like us to know?",
            textInputAction: TextInputAction.done,
            minLines: 4,
            maxLines: 6,
          ),
          32.heightBox,
          PrimaryTextField(
            controller: suggestLanguageController,
            title: "Would you like to suggest a language? If yes, enter language below",
            hintText: "Write your suggestion here",
            textInputAction: TextInputAction.next,
            minLines: 2,
            maxLines: 3,
          ),
          32.heightBox,
          TitledDropDown<String>(
            title: "Language Country",
            titles: kCountries.keys.toList(),
            items: kCountries.keys.toList(),
            value: selectedCountry.value,
            onChanged: (value) => selectedCountry.value = value,
          ),
          48.heightBox,
          PrimaryButton(
            width: 0.6.sw,
            onTap: () {
              final suggestion = suggestLanguageController.text.trim();
              final reason = reasonController.text.trim();
              final country = selectedCountry.value;
              if (suggestion.isEmpty && reason.isEmpty) {
                VxToast.show(context, msg: 'Please fill in some fields');
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
                body += 'What would you like us to know:\n$reason\n\n';
              }

              if (suggestion.isNotEmpty) {
                body +=
                    'Would you like to suggest a language? If yes, enter language below:\n$suggestion\n\n';
              }
              if (country != null) {
                body += 'Language Country:\n$country\n\n';
              }

              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'lingafriq@gmail.com',
                query: encodeQueryParameters(<String, String>{
                  'subject': 'Feedback Form on Mobile App',
                  'body': body,
                }),
              );
              kLaunchUrl(emailLaunchUri.toString());
              // Navigator.of(context).pop();
            },
            text: "Submit",
          )
        ],
      ).px16().scrollVertical(),
    );
  }
}
