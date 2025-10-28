import 'package:flutter/material.dart';

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showDropdown,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              widget.value ?? 'Select class',
              style: TextStyle(fontSize: 14),
            ),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showDropdown() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: 200,
            child: ListView(
              shrinkWrap: true,
              children:
                  widget.items.map((String item) {
                    return ListTile(
                      title: Text(item),
                      onTap: () {
                        widget.onChanged(item);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}
