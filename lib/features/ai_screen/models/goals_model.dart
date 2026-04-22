import 'package:hive_flutter/hive_flutter.dart';

/// Hive-persisted savings goal.
/// typeId: 2  (0 = Expense, 1 = Budget)
@HiveType(typeId: 2)
class GoalEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String emoji;
  @HiveField(3)
  double target;
  @HiveField(4)
  double saved;
  @HiveField(5)
  int daysLeft;

  GoalEntry({
    required this.id,
    required this.name,
    required this.emoji,
    required this.target,
    required this.saved,
    required this.daysLeft,
  });

  double get progress => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0;
  double get remaining => (target - saved).clamp(0, target);
}

class GoalEntryAdapter extends TypeAdapter<GoalEntry> {
  @override
  final int typeId = 2;

  @override
  GoalEntry read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{
      for (int i = 0; i < n; i++) r.readByte(): r.read(),
    };
    return GoalEntry(
      id: f[0] as String? ?? '',
      name: f[1] as String? ?? '',
      emoji: f[2] as String? ?? '🎯',
      target: (f[3] as num?)?.toDouble() ?? 0,
      saved: (f[4] as num?)?.toDouble() ?? 0,
      daysLeft: f[5] as int? ?? 30,
    );
  }

  @override
  void write(BinaryWriter w, GoalEntry o) {
    w
      ..writeByte(6)
      ..writeByte(0)
      ..write(o.id)
      ..writeByte(1)
      ..write(o.name)
      ..writeByte(2)
      ..write(o.emoji)
      ..writeByte(3)
      ..write(o.target)
      ..writeByte(4)
      ..write(o.saved)
      ..writeByte(5)
      ..write(o.daysLeft);
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object o) => o is GoalEntryAdapter && typeId == o.typeId;
}
