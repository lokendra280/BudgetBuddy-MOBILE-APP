// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalTransactionAdapter extends TypeAdapter<GoalTransaction> {
  @override
  final int typeId = 4;

  @override
  GoalTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalTransaction(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GoalTransaction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
