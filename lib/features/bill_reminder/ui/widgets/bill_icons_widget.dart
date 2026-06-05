// import 'dart:ui';

// import 'package:flutter/widgets.dart';

// class BillCategoryIcon extends StatelessWidget {
//   final BillCategory category;
//   final double size;

//   const BillCategoryIcon({super.key, required this.category, this.size = 24});

//   @override
//   Widget build(BuildContext context) {
//     String asset;

//     switch (category) {
//       case BillCategory.bills:
//         asset = Assets.bills;
//         break;
//       case BillCategory.loanEmi:
//         asset = Assets.loan;
//         break;
//       case BillCategory.subscription:
//         asset = Assets.subscription;
//         break;
//       case BillCategory.rent:
//         asset = Assets.rent;
//         break;
//       case BillCategory.insurance:
//         asset = Assets.insurance;
//         break;
//       case BillCategory.other:
//         asset = Assets.other;
//         break;
//     }

//     return Image.asset(asset, width: size, height: size);
//   }
// }
