import 'package:flutter/material.dart';

class JsonExpansionTile extends StatelessWidget {
  final String title;
  final String jsonString;
  final bool initiallyExpanded;

  const JsonExpansionTile({
    super.key,
    required this.title,
    required this.jsonString,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = initiallyExpanded
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleSmall;

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Text(title, style: titleStyle),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant)),
            child: SelectableText(
              jsonString,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
