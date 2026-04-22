import 'package:expensetracker/common/app_theme.dart';
import 'package:expensetracker/common/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.border),
      ),
      child: Row(
        children: [
          _B(
            Icons.dark_mode_rounded,
            'Dark',
            mode == ThemeMode.dark,
            () => ref.read(themeProvider.notifier).setMode(ThemeMode.dark),
          ),
          _B(
            Icons.light_mode_rounded,
            'Light',
            mode == ThemeMode.light,
            () => ref.read(themeProvider.notifier).setMode(ThemeMode.light),
          ),
          _B(
            Icons.brightness_auto_rounded,
            'System',
            mode == ThemeMode.system,
            () => ref.read(themeProvider.notifier).setMode(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _B extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _B(this.icon, this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : context.c.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : context.c.textMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
