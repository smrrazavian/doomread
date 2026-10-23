import 'package:flutter/material.dart';

// ponytail: Books, Building and Friends get real screens
// in tickets #2, #10 and #16.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)));
}
