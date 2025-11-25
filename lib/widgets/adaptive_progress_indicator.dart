import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

class AdaptiveProgressIndicator extends StatelessWidget {
  final String? message;
  const AdaptiveProgressIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (Platform.isIOS)
          const CupertinoActivityIndicator()
        else
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        const SizedBox(height: 16),
        Text(
          message ?? 'Please Wait',
          style: TextStyle(
            color: Theme.of(context).dividerColor.withOpacity(0.60),
            fontSize: 16.sp,
          ),
        ),
      ],
    ));
  }
}
