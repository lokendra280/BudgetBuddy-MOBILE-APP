// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      date: fields[4] as DateTime,
      isIncome: fields[5] as bool,
      currency: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.isIncome)
      ..writeByte(6)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 1;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      monthlyLimit: fields[0] as double,
      streakDays: fields[1] as int,
      lastActiveDate: fields[2] as String,
      referralCode: fields[3] as String?,
      referralCount: fields[4] as int,
      currency: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.monthlyLimit)
      ..writeByte(1)
      ..write(obj.streakDays)
      ..writeByte(2)
      ..write(obj.lastActiveDate)
      ..writeByte(3)
      ..write(obj.referralCode)
      ..writeByte(4)
      ..write(obj.referralCount)
      ..writeByte(5)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
