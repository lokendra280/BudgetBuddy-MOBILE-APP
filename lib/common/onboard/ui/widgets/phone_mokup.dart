import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/onboard/ui/widgets/corner_widget.dart';
import 'package:flutter/material.dart';

class PhoneMockup extends StatelessWidget {
  final double scanProgress;
  const PhoneMockup({required this.scanProgress});

  static const _items = ['Milk', 'Bread', 'Eggs', 'Coffee'];
  static const _prices = ['Rs.120', 'Rs.45', 'Rs.180', 'Rs.60'];

  @override
  Widget build(BuildContext context) => Container(
    width: 180,
    height: 250,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: AppColors.primaryColor.withOpacity(0.15),
          blurRadius: 60,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          // Receipt content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Top notch pill
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('🧾', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 10),
                ...List.generate(
                  _items.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _items[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                        Text(
                          _prices[i],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Animated scan line
          Positioned(
            top: 250 * scanProgress,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primaryColor.withOpacity(0.8),
                    AppColors.secondaryColor,
                    AppColors.primaryColor.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Corner brackets
          ..._corners(),
        ],
      ),
    ),
  );

  List<Widget> _corners() {
    const size = 14.0;
    const pad = 8.0;
    return [
      Positioned(
        top: pad,
        left: pad,
        child: CornerWidget(top: true, left: true),
      ),
      Positioned(
        top: pad,
        right: pad,
        child: CornerWidget(top: true, left: false),
      ),
      Positioned(
        bottom: pad,
        left: pad,
        child: CornerWidget(top: false, left: true),
      ),
      Positioned(
        bottom: pad,
        right: pad,
        child: CornerWidget(top: false, left: false),
      ),
    ];
  }
}
