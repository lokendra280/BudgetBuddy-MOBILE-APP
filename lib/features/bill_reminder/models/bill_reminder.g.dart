// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillReminderAdapter extends TypeAdapter<BillReminder> {
  @override
  final int typeId = 3;

  @override
  BillReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillReminder(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      category: fields[3] as String,
      dayOfMonth: fields[4] as int,
      isActive: fields[5] as bool,
      currency: fields[6] as String,
      remindDaysBefore: fields[7] as int,
      isRecurring: fields[8] as bool,
      nextDueDate: fields[9] as DateTime?,
      emoji: fields[10] as String,
      isPaid: fields[11] as bool,
      lastPaidAt: fields[12] as DateTime?,
      paymentHistory: (fields[13] as List).cast<DateTime>(),
      notes: fields[14] as String,
      synced: fields[15] as bool,
      updatedAt: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BillReminder obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.dayOfMonth)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.currency)
      ..writeByte(7)
      ..write(obj.remindDaysBefore)
      ..writeByte(8)
      ..write(obj.isRecurring)
      ..writeByte(9)
      ..write(obj.nextDueDate)
      ..writeByte(10)
      ..write(obj.emoji)
      ..writeByte(11)
      ..write(obj.isPaid)
      ..writeByte(12)
      ..write(obj.lastPaidAt)
      ..writeByte(13)
      ..write(obj.paymentHistory)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.synced)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
