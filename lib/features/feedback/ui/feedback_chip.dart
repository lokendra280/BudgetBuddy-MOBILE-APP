// // select_chip.dart
// import 'package:budgetBuddy/common/constant/app_typography.dart';
// import 'package:flutter/material.dart';

// class SelectChip extends StatelessWidget {
//   final String label;
//   final Color color;
//   final bool selected;
//   final VoidCallback onTap;
//   final bool expand;

//   const SelectChip({
//     super.key,
//     required this.label,
//     required this.color,
//     required this.selected,
//     required this.onTap,
//     this.expand = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final chip = GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
//         decoration: BoxDecoration(
//           color: selected
//               ? color.withOpacity(0.12)
//               : Theme.of(context).colorScheme.surfaceVariant,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: selected ? color : Colors.transparent,
//             width: 1.5,
//           ),
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: AppTextStyleX.chip(context, selected: selected, color: color),
//           ),
//         ),
//       ),
//     );
//     return expand ? Expanded(child: chip) : chip;
//   }
// }