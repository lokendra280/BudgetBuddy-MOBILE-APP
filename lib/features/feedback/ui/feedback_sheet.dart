// // feedback_sheet.dart
// import 'package:budgetBuddy/common/constant/app_typography.dart';
// import 'package:budgetBuddy/features/feedback/enum/feedback_enum.dart';
// import 'package:budgetBuddy/features/feedback/services/feedback_promt_services.dart';
// import 'package:budgetBuddy/features/feedback/services/feedback_services.dart';
// import 'package:budgetBuddy/features/feedback/ui/feedback_chip.dart';
// import 'package:budgetBuddy/features/feedback/ui/mood_selector.dart';
// import 'package:flutter/material.dart';

// Future<void> showFeedbackSheet(
//   BuildContext context, {
//   bool isDailyPrompt = false,
// }) {
//   if (isDailyPrompt) FeedbackPromptService.markShownToday();
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => FeedbackSheet(isDailyPrompt: isDailyPrompt),
//   );
// }

// class FeedbackSheet extends StatefulWidget {
//   final bool isDailyPrompt;
//   const FeedbackSheet({super.key, this.isDailyPrompt = false});

//   @override
//   State<FeedbackSheet> createState() => _FeedbackSheetState();
// }

// class _FeedbackSheetState extends State<FeedbackSheet> {
//   final _nameCtrl = TextEditingController();
//   final _countryCtrl = TextEditingController();
//   final _messageCtrl = TextEditingController();
//   FeedbackType _type = FeedbackType.dailyCheckIn;
//   int? _mood;
//   bool _submitting = false;

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _countryCtrl.dispose();
//     _messageCtrl.dispose();
//     super.dispose();
//   }

//   bool get _isValid =>
//       _nameCtrl.text.trim().isNotEmpty &&
//       _countryCtrl.text.trim().isNotEmpty &&
//       _messageCtrl.text.trim().isNotEmpty;

//   Future<void> _submit() async {
//     if (!_isValid) return;
//     setState(() => _submitting = true);
//     try {
//       await FeedbackService.submit(
//         name: _nameCtrl.text,
//         country: _countryCtrl.text,
//         message: _messageCtrl.text,
//         type: _type,
//         mood: widget.isDailyPrompt ? _mood : null,
//       );
//       if (!mounted) return;
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Thanks for the feedback! 🙌')),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _submitting = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             "Couldn't send feedback — check your connection and try again.",
//           ),
//         ),
//       );
//     }
//   }

//   void _skip() => Navigator.pop(context);

//   @override
//   Widget build(BuildContext context) {
//     final bottom = MediaQuery.of(context).viewInsets.bottom;
//     return Container(
//       margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//       padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
//       decoration: BoxDecoration(
//         // TODO: swap for your card background from AppColors / app_theme.dart
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Container(
//                 width: 36,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).dividerColor,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               widget.isDailyPrompt ? 'How was your day?' : 'Send Feedback',
//               style: context.t.h3,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               widget.isDailyPrompt
//                   ? "We'd love a quick word — takes 10 seconds."
//                   : 'Tell us what\'s working, what\'s not, or what you\'d like to see.',
//               style: context.t.bodySub,
//             ),
//             const SizedBox(height: 18),
//             if (widget.isDailyPrompt) ...[
//               MoodSelector(
//                 selected: _mood,
//                 onSelect: (m) => setState(() => _mood = m),
//               ),
//               const SizedBox(height: 18),
//             ],
//             Text('Type', style: context.t.overline),
//             const SizedBox(height: 8),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: FeedbackType.values
//                   .map(
//                     (t) => SelectChip(
//                       label: t.label,
//                       color: Theme.of(context).colorScheme.primary,
//                       selected: _type == t,
//                       onTap: () => setState(() => _type = t),
//                       expand: false,
//                     ),
//                   )
//                   .toList(),
//             ),
//             const SizedBox(height: 14),
//             _Field(
//               controller: _nameCtrl,
//               hint: 'Your name',
//               onChanged: () => setState(() {}),
//             ),
//             const SizedBox(height: 10),
//             _Field(
//               controller: _countryCtrl,
//               hint: 'Your country',
//               onChanged: () => setState(() {}),
//             ),
//             const SizedBox(height: 10),
//             _Field(
//               controller: _messageCtrl,
//               hint: _type == FeedbackType.bugReport
//                   ? 'Describe the bug — what happened, what you expected'
//                   : 'Your feedback',
//               maxLines: 4,
//               onChanged: () => setState(() {}),
//             ),
//             const SizedBox(height: 18),
//             Row(
//               children: [
//                 if (widget.isDailyPrompt)
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: _submitting ? null : _skip,
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: Text('Skip', style: context.t.buttonSmall),
//                     ),
//                   ),
//                 if (widget.isDailyPrompt) const SizedBox(width: 10),
//                 Expanded(
//                   flex: 2,
//                   child: ElevatedButton(
//                     onPressed: (_isValid && !_submitting) ? _submit : null,
//                     style: ElevatedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: _submitting
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )
//                         : Text(
//                             'Submit',
//                             style: context.t.button.copyWith(
//                               color: Colors.white,
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _Field extends StatelessWidget {
//   final TextEditingController controller;
//   final String hint;
//   final int maxLines;
//   final VoidCallback? onChanged;
//   const _Field({
//     required this.controller,
//     required this.hint,
//     this.maxLines = 1,
//     this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) => TextField(
//     controller: controller,
//     maxLines: maxLines,
//     onChanged: (_) => onChanged?.call(),
//     style: context.t.body,
//     decoration: InputDecoration(
//       hintText: hint,
//       hintStyle: context.t.labelMuted,
//       filled: true,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide.none,
//       ),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//     ),
//   );
// }
