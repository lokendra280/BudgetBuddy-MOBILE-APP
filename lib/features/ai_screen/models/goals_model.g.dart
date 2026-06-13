// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalEntryAdapter extends TypeAdapter<GoalEntry> {
  @override
  final int typeId = 2;

  @override
  GoalEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalEntry(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      target: fields[3] as double,
      saved: fields[4] as double,
      daysLeft: fields[5] as int,
      transactions: (fields[6] as List).cast<GoalTransaction>(),
    );
  }

  @override
  void write(BinaryWriter writer, GoalEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.target)
      ..writeByte(4)
      ..write(obj.saved)
      ..writeByte(5)
      ..write(obj.daysLeft)
      ..writeByte(6)
      ..write(obj.transactions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
