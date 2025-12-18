import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/primary_button.dart';

class StreamErrorWidget extends StatelessWidget {
  final Object error;
  final GestureTapCallback? onTryAgain;
  const StreamErrorWidget({
    Key? key,
    required this.error,
    this.onTryAgain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 75.sp,
            ),
            const SizedBox(height: 12),
            Text(
              () {
                if (kDebugMode) return error.toString();
                return "We're sorry";
              }.call(),
              maxLines: 4,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.adaptive70,
                fontSize: 22.sp,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              () {
                if (error.toString().toLowerCase().contains('SocketException'.toLowerCase())) {
                  return 'No internet Connection';
                }
                if (kDebugMode) return error.toString();
                return "Oops, an error occured. Try again";
              }.call(),
              textAlign: TextAlign.center,
              maxLines: 4,
              style: TextStyle(
                color: context.adaptive54,
                fontSize: 18.sp,
              ),
            ),
            const SizedBox(height: 24),
            if (onTryAgain != null)
              PrimaryButton(
                onTap: onTryAgain!,
                text: "Try Again",
              ).w(0.5.sw),
            // TextButton(
            //   onPressed: onTryAgain,
            //   child: Text(
            //     'Try Again',
            //     style: TextStyle(
            //       color: context.adaptive,
            //       fontSize: 24.sp,
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
