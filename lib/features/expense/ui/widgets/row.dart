import 'package:flutter/material.dart';

class RowData {
  final tc = TextEditingController(); // title
  final ac = TextEditingController(); // amount
  String catName;
  RowData(this.catName);
  void dispose() {
    tc.dispose();
    ac.dispose();
  }

  bool get valid =>
      tc.text.trim().isNotEmpty &&
      (double.tryParse(ac.text.replaceAll(',', '')) ?? 0) > 0;
  double get parsedAmount => double.tryParse(ac.text.replaceAll(',', '')) ?? 0;
}
