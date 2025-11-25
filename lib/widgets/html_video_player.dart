import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lingafriq/utils/utils.dart';

class HtmlVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const HtmlVideoPlayer({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  State<HtmlVideoPlayer> createState() => _HtmlVideoPlayerState();
}

class _HtmlVideoPlayerState extends State<HtmlVideoPlayer> {
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  late InAppWebViewController webViewController;
  @override
  Widget build(BuildContext context) {
    final url = 'https://itsatifsiddiqui.github.io/lingafriq.html?video=${widget.videoUrl}';
    url.log("VIDEO URL");
    return InAppWebView(
      onEnterFullscreen: (controller) async {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      },
      onExitFullscreen: (controller) async {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      },
      initialUrlRequest: URLRequest(
        url: WebUri(url)
      ),
      // initialFile: 'assets/index.html',
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onProgressChanged: (controller, progress) {
        this.progress.value = progress / 100.0;
      },
      onConsoleMessage: (controller, consoleMessage) {
        print("onConsoleMessage: $consoleMessage");
      },
    );
  }
}
