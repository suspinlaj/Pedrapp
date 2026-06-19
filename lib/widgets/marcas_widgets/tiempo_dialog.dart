import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TiempoDialog extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color colorFondo;
  final bool isDecimal;

  const TiempoDialog({
    super.key,
    required this.label, 
    required this.controller, 
    required this.colorFondo, 
    this.isDecimal = false
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          floatingLabelStyle: TextStyle(color: colorFondo, fontWeight: FontWeight.bold),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorFondo, width: 2.0),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorFondo, width: 2.0),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    );
  }
}