import 'package:flutter/material.dart';
import 'package:muzee/gen/colors.gen.dart';

class Loading extends StatelessWidget {
  final String? title;

  const Loading({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: MyColors.primary.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.circular(40)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              if (title != null && title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(title!),
                )
            ],
          ),
        ),
      ),
    );
  }
}
