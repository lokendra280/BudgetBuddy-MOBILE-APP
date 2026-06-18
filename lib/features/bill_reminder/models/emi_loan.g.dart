// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emi_loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmiLoanAdapter extends TypeAdapter<EmiLoan> {
  @override
  final int typeId = 6;

  @override
  EmiLoan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmiLoan(
      id: fields[0] as String,
      title: fields[1] as String,
      lenderName: fields[2] as String,
      principalAmount: fields[3] as double,
      emiAmount: fields[4] as double,
      interestRate: fields[5] as double,
      tenureMonths: fields[6] as int,
      startDate: fields[7] as DateTime,
      dayOfMonth: fields[8] as int,
      currency: fields[9] as String,
      category: fields[10] as String,
      emoji: fields[11] as String,
      isActive: fields[12] as bool,
      payments: (fields[13] as List).cast<EmiPayment>(),
      totalExtraPayments: fields[14] as double,
      remindDaysBefore: fields[15] as int,
      remindersEnabled: fields[16] as bool,
      notes: fields[17] as String,
      synced: fields[18] as bool,
      updatedAt: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EmiLoan obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.lenderName)
      ..writeByte(3)
      ..write(obj.principalAmount)
      ..writeByte(4)
      ..write(obj.emiAmount)
      ..writeByte(5)
      ..write(obj.interestRate)
      ..writeByte(6)
      ..write(obj.tenureMonths)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.dayOfMonth)
      ..writeByte(9)
      ..write(obj.currency)
      ..writeByte(10)
      ..write(obj.category)
      ..writeByte(11)
      ..write(obj.emoji)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.payments)
      ..writeByte(14)
      ..write(obj.totalExtraPayments)
      ..writeByte(15)
      ..write(obj.remindDaysBefore)
      ..writeByte(16)
      ..write(obj.remindersEnabled)
      ..writeByte(17)
      ..write(obj.notes)
      ..writeByte(18)
      ..write(obj.synced)
      ..writeByte(19)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmiLoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EmiPaymentAdapter extends TypeAdapter<EmiPayment> {
  @override
  final int typeId = 5;

  @override
  EmiPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmiPayment(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      amount: fields[2] as double,
      isExtraPayment: fields[3] as bool,
      note: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmiPayment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isExtraPayment)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmiPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
