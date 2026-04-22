import 'dart:io';
import 'dart:typed_data';
import 'package:expensetracker/features/auth/providers/auth_service.dart';
import 'package:expensetracker/features/expense/services/expenses_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  // ── Capture RepaintBoundary → PNG bytes ────────────────────────────────
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ── Build report card and share ────────────────────────────────────────
  static Future<void> shareReport(BuildContext context) async {
    final sym = ExpenseService.symbol;
    final expenses = ExpenseService.forMonth(DateTime.now());
    final totalExp = ExpenseService.expenseFor(expenses);
    final totalInc = ExpenseService.incomeFor(expenses);
    final net = totalInc - totalExp;
    final budget = ExpenseService.budget;
    final (thisW, lastW) = ExpenseService.weekComparison();
    final catMap = ExpenseService.byCategory(
      expenses.where((e) => !e.isIncome).toList(),
    );
    final topCat = catMap.isNotEmpty ? catMap.entries.first.key : 'None';
    final msg = ExpenseService.wasteMessage(thisW, lastW);

    final key = GlobalKey();
    final card = RepaintBoundary(
      key: key,
      child: _ReportCard(
        sym: sym,
        totalExp: totalExp,
        totalInc: totalInc,
        net: net,
        streak: budget.streakDays,
        topCat: topCat,
        msg: msg,
        name: AuthService.userName,
      ),
    );

    late OverlayEntry oe;
    oe = OverlayEntry(
      builder: (_) => Positioned(
        left: -9999,
        top: -9999,
        child: Material(color: Colors.transparent, child: card),
      ),
    );
    Overlay.of(context).insert(oe);
    await Future.delayed(const Duration(milliseconds: 250));
    final bytes = await captureWidget(key);
    oe.remove();

    if (bytes == null) {
      // Text-only fallback
      Share.share(
        '💸 My SpendSense Report\n'
        '${sym}${totalExp.toStringAsFixed(0)} spent · ${sym}${totalInc.toStringAsFixed(0)} earned\n'
        'Net: ${net >= 0 ? '+' : ''}${sym}${net.abs().toStringAsFixed(0)}\n'
        '🔥 ${budget.streakDays} day streak\n\n$msg\n\n'
        'Track yours → SpendSense 📊',
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spendsense_report.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: '💸 My SpendSense Report — download and track yours too!',
      subject: 'SpendSense Monthly Report',
    );
  }
}

// ── Visual report card (rendered off-screen then captured) ─────────────────
class _ReportCard extends StatelessWidget {
  final String sym, topCat, msg, name;
  final double totalExp, totalInc, net;
  final int streak;
  const _ReportCard({
    required this.sym,
    required this.totalExp,
    required this.totalInc,
    required this.net,
    required this.streak,
    required this.topCat,
    required this.msg,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final nc = net >= 0 ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D0D1A), Color(0xFF1A1040)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: Text('💸', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SpendSense',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  Text(
                    name.isEmpty ? 'Monthly Report' : '$name\'s Report',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF52526E),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak days',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Net
          const Text(
            'Net balance',
            style: TextStyle(fontSize: 11, color: Color(0xFF52526E)),
          ),
          const SizedBox(height: 4),
          Text(
            '${net >= 0 ? '+' : ''}$sym${net.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: nc,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Stat boxes
          Row(
            children: [
              _SB(
                '📤 Spent',
                '$sym${totalExp.toStringAsFixed(0)}',
                const Color(0xFFF43F5E),
              ),
              const SizedBox(width: 8),
              _SB(
                '📥 Earned',
                '$sym${totalInc.toStringAsFixed(0)}',
                const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              _SB('🏆 Top', topCat, const Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 14),
          // Insight
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
              ),
            ),
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Track your finances → SpendSense 📊',
              style: TextStyle(fontSize: 10, color: Color(0xFF52526E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SB extends StatelessWidget {
  final String l, v;
  final Color c;
  const _SB(this.l, this.v, this.c);
  @override
  Widget build(BuildContext ctx) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l,
            style: const TextStyle(fontSize: 9, color: Color(0xFF52526E)),
          ),
          const SizedBox(height: 3),
          Text(
            v,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: c,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
