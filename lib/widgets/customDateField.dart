import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String errorText;

  const DateField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.errorText,
  });

  @override
  _DateFieldState createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2025, 12, 31),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        widget.controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.labelText),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              controller: widget.controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return widget.errorText;
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
              ),
              style: TextStyle(color: Colors.indigo, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
