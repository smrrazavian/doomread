import 'package:flutter/material.dart';

// ponytail: Friends gets a real screen in ticket #16.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)));
}
