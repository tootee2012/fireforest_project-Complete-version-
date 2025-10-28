import 'package:flutter/material.dart';

class CustomRadio extends StatelessWidget {
  final String value;
  final String? groupValue;
  final String labelText;
  final ValueChanged<String?>? onChanged;

  const CustomRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.labelText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        Text(labelText),
      ],
    );
  }
}
