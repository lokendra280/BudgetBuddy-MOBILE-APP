// lib/expense/screens/bill_scan_result_view.dart
import 'dart:io';
import 'package:budgetBuddy/features/expense/services/bill_scaning_service.dart';
import 'package:flutter/material.dart';

class BillScanResultView extends StatefulWidget {
  final BillScanResult result;
  final File previewFile;

  const BillScanResultView({
    super.key,
    required this.result,
    required this.previewFile,
  });

  @override
  State<BillScanResultView> createState() => _BillScanResultViewState();
}

class _BillScanResultViewState extends State<BillScanResultView> {
  late final List<BillItem> _items = List.of(widget.result.items);
  late final Set<int> _selected = List.generate(
    _items.length,
    (i) => i,
  ).toSet();

  double get _selectedTotal =>
      _selected.fold(0, (sum, i) => sum + _items[i].amount);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.result.merchant ?? 'Scanned Bill')),
      body: Column(
        children: [
          _buildSummaryCard(scheme),
          Expanded(child: _buildItemList(scheme)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(true),
          child: Text(
            'Add ${_selected.length} item${_selected.length == 1 ? '' : 's'} · '
            '${widget.result.detectedCurrency ?? ''} ${_selectedTotal.toStringAsFixed(2)}',
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              widget.previewFile,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.merchant ?? 'Unknown merchant',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_items.length} items detected',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (widget.result.totalAmount != null)
            Text(
              '${widget.result.detectedCurrency ?? ''} '
              '${widget.result.totalAmount!.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _buildItemList(ColorScheme scheme) {
    if (_items.isEmpty) {
      return const Center(child: Text('No line items detected'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final isSelected = _selected.contains(index);

        // Items "land" one after another instead of appearing all at once —
        // each row's entrance is delayed a bit more than the last.
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 320 + index * 70),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 16),
                child: child,
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: isSelected ? scheme.surfaceContainerHigh : scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (v) => setState(() {
                v == true ? _selected.add(index) : _selected.remove(index);
              }),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(item.name),
              subtitle: Text(item.currency),
              secondary: Text(
                item.amount.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
      },
    );
  }
}
