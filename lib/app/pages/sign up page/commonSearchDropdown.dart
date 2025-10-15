import 'package:flutter/material.dart';

class CommonDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedValue;
  final String hintText;
  final void Function(T?) onChanged;

  const CommonDropdown({
    Key? key,
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: MaterialStateProperty.all(Colors.grey.shade100),
            padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 8)),
          ),
        ),
      ),
      child: DropdownButton<T>(
        isExpanded: true,
        value: selectedValue,
        hint: Text(hintText),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: TextStyle(fontSize: 16, color: Colors.blueAccent),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
