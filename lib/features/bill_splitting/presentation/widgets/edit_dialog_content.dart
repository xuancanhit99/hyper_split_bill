import 'package:flutter/material.dart';

// --- Stateful Widget for Description Dialog Content ---
class DescriptionDialogContent extends StatefulWidget {
  final String initialValue;

  const DescriptionDialogContent({super.key, required this.initialValue});

  @override
  // Make state class public
  DescriptionDialogContentState createState() =>
      DescriptionDialogContentState();
}

// Make state class public
class DescriptionDialogContentState extends State<DescriptionDialogContent> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get currentValue => controller.text.trim();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration:
          const InputDecoration(hintText: 'Enter description or store name'),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

// --- Stateful Widget for Numeric Dialog Content ---
class NumericDialogContent extends StatefulWidget {
  final String initialValue;
  final String? hintText;
  final String? valueSuffix;
  final bool allowNegative;
  final num? Function(dynamic, {bool allowNegative})
      parseNumFunc; // Pass helper

  const NumericDialogContent({
    super.key,
    required this.initialValue,
    this.hintText,
    this.valueSuffix,
    this.allowNegative = false,
    required this.parseNumFunc,
  });

  @override
  // Make state class public
  NumericDialogContentState createState() => NumericDialogContentState();
}

// Make state class public
class NumericDialogContentState extends State<NumericDialogContent> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get currentValue => controller.text.isEmpty ? '0' : controller.text;
  bool validate() => formKey.currentState!.validate();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(
            decimal: true, signed: widget.allowNegative),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Enter value',
          suffixText: widget.valueSuffix,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return null; // Allow empty, treat as 0
          }
          final number =
              widget.parseNumFunc(value, allowNegative: widget.allowNegative);
          if (number == null) {
            return 'Please enter a valid number';
          }
          return null; // Valid
        },
      ),
    );
  }
}
