import 'package:flutter/material.dart';

class PlaceHolderWidget extends StatelessWidget {
  final String text;

  const PlaceHolderWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}