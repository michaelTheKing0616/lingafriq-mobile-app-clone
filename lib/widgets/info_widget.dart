import 'package:flutter/material.dart';
import 'package:lingafriq/utils/utils.dart';

class InfoWidget extends StatelessWidget {
  final String text;
  final String? subText;
  final VoidCallback? onRefresh;
  const InfoWidget({
    Key? key,
    required this.text,
    this.subText,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: SingleChildScrollView(
          physics: onRefresh == null
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 75.sp,
              ),
              const SizedBox(height: 20),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).dividerColor.withOpacity(0.54),
                  fontSize: 22.sp,
                ),
              ).px16(),
              const SizedBox(height: 12),
              if (subText != null)
                Text(
                  subText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).dividerColor.withOpacity(0.54),
                    fontSize: 16.sp,
                  ),
                ).px32(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
