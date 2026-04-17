// import 'package:expensetracker/common/app_theme.dart';
// import 'package:expensetracker/common/common_widget.dart';
// import 'package:expensetracker/common/services/premium_service.dart';
// import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';

// class PaywallScreen extends StatefulWidget {
//   const PaywallScreen({super.key});
//   @override
//   State<PaywallScreen> createState() => _State();
// }

// class _State extends State<PaywallScreen> {
//   bool _loading = false;
//   int _selected = 0; // 0 = lifetime, 1 = monthly

//   Future<void> _buy() async {
//     if (PremiumService.isPremium) {
//       Navigator.pop(context);
//       return;
//     }
//     if (PremiumService.products.isEmpty) {
//       _showSnack('Store unavailable. Try again later.');
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       final product = PremiumService
//           .products[_selected.clamp(0, PremiumService.products.length - 1)];
//       await PremiumService.buy(product);
//     } catch (e) {
//       _showSnack('Purchase failed. Please try again.');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _restore() async {
//     setState(() => _loading = true);
//     await PremiumService.restore();
//     if (mounted) setState(() => _loading = false);
//     if (PremiumService.isPremium && mounted) {
//       _showSnack('Premium restored! ✓');
//       Navigator.pop(context);
//     } else {
//       _showSnack('No previous purchase found.');
//     }
//   }

//   void _showSnack(String msg) => ScaffoldMessenger.of(
//     context,
//   ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kAccent));

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: context.c.bg,
//       body: Stack(
//         children: [
//           // Background glow
//           Positioned(
//             top: -80,
//             right: -80,
//             child: Container(
//               width: 280,
//               height: 280,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 gradient: RadialGradient(
//                   colors: [AppColors.primaryColor.withOpacity(0.2), Colors.transparent],
//                 ),
//               ),
//             ),
//           ),

//           SafeArea(
//             child: Column(
//               children: [
//                 // ── Header ──
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Icon(
//                           Icons.close_rounded,
//                           color: context.c.textMuted,
//                         ),
//                       ),
//                       const Spacer(),
//                       if (PremiumService.isPremium) const PremiumBadge(),
//                     ],
//                   ),
//                 ),

//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
//                     child: Column(
//                       children: [
//                         // ── Hero ──
//                         Container(
//                           width: 72,
//                           height: 72,
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
//                             ),
//                             borderRadius: BorderRadius.circular(22),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFFFFD700).withOpacity(0.4),
//                                 blurRadius: 24,
//                                 offset: const Offset(0, 8),
//                               ),
//                             ],
//                           ),
//                           child: const Center(
//                             child: Text('⭐', style: TextStyle(fontSize: 34)),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         const Text(
//                           'SpendSense Pro',
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Unlock everything. No ads. Forever.',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: context.c.textSub,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),

//                         const SizedBox(height: 32),

//                         // ── Features ──
//                         AppCard(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: const [
//                               PremiumFeatureRow('🚫', 'Remove all ads forever'),
//                               PremiumFeatureRow(
//                                 '📊',
//                                 'Advanced spending insights',
//                               ),
//                               PremiumFeatureRow(
//                                 '🔓',
//                                 'Unlock all locked charts',
//                               ),
//                               PremiumFeatureRow('📤', 'Export data as CSV'),
//                               PremiumFeatureRow(
//                                 '🎨',
//                                 'Custom categories & themes',
//                               ),
//                               PremiumFeatureRow('🔔', 'Smart budget alerts'),
//                             ],
//                           ),
//                         ),

//                         const SizedBox(height: 24),

//                         // ── Plan selector ──
//                         Row(
//                           children: [
//                             _PlanCard(
//                               label: 'Lifetime',
//                               price: '₹499',
//                               sub: 'one-time',
//                               popular: true,
//                               selected: _selected == 0,
//                               onTap: () => setState(() => _selected = 0),
//                             ),
//                             const SizedBox(width: 12),
//                             _PlanCard(
//                               label: 'Monthly',
//                               price: '₹79',
//                               sub: 'per month',
//                               popular: false,
//                               selected: _selected == 1,
//                               onTap: () => setState(() => _selected = 1),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 24),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // ── CTA ──
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
//                   child: Column(
//                     children: [
//                       SizedBox(
//                         width: double.infinity,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: _loading ? null : _buy,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             shadowColor: Colors.transparent,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             padding: EdgeInsets.zero,
//                           ),
//                           child: Ink(
//                             decoration: BoxDecoration(
//                               gradient: const LinearGradient(
//                                 colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Center(
//                               child: _loading
//                                   ? const SizedBox(
//                                       width: 22,
//                                       height: 22,
//                                       child: CircularProgressIndicator(
//                                         color: Colors.white,
//                                         strokeWidth: 2,
//                                       ),
//                                     )
//                                   : Text(
//                                       PremiumService.isPremium
//                                           ? 'Already Premium ✓'
//                                           : _selected == 0
//                                           ? 'Get Lifetime — ₹499'
//                                           : 'Subscribe — ₹79/mo',
//                                       style: const TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w800,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       GestureDetector(
//                         onTap: _restore,
//                         child: Text(
//                           'Restore purchase',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: context.c.textSub,
//                             decoration: TextDecoration.underline,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Cancel anytime · Secure payment via App Store / Play Store',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: context.c.textSub,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PlanCard extends StatelessWidget {
//   final String label, price, sub;
//   final bool popular, selected;
//   final VoidCallback onTap;
//   const _PlanCard({
//     required this.label,
//     required this.price,
//     required this.sub,
//     required this.popular,
//     required this.selected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 180),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: selected ? AppColors.primaryColor.withOpacity(0.12) : context.c.surface,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: selected ? AppColors.primaryColor : context.c.border,
//               width: selected ? 1.5 : 1,
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (popular)
//                 Container(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 3,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
//                     ),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Text(
//                     'BEST',
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 price,
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                   color: selected ? AppColors.primaryColor : Colors.white,
//                 ),
//               ),
//               Text(
//                 sub,
//                 style: TextStyle(fontSize: 10, color: context.c.textSub),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
