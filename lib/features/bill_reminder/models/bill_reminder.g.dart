// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
part of 'bill_reminder.dart';

class BillReminderAdapter extends TypeAdapter<BillReminder> {
  @override
  final int typeId = 3;

  @override
  BillReminder read(BinaryReader r) => BillReminder(
    id: r.readString(),
    title: r.readString(),
    amount: r.readDouble(),
    category: r.readString(),
    dayOfMonth: r.readInt(),
    isActive: r.readBool(),
    currency: r.readString(),
    remindDaysBefore: r.readInt(),
    isRecurring: r.readBool(),
    nextDueDate: r.readBool()
        ? DateTime.fromMillisecondsSinceEpoch(r.readInt())
        : null,
    emoji: r.readString(),
  );

  @override
  void write(BinaryWriter w, BillReminder o) {
    w.writeString(o.id);
    w.writeString(o.title);
    w.writeDouble(o.amount);
    w.writeString(o.category);
    w.writeInt(o.dayOfMonth);
    w.writeBool(o.isActive);
    w.writeString(o.currency);
    w.writeInt(o.remindDaysBefore);
    w.writeBool(o.isRecurring);
    final hasDate = o.nextDueDate != null;
    w.writeBool(hasDate);
    if (hasDate) w.writeInt(o.nextDueDate!.millisecondsSinceEpoch);
    w.writeString(o.emoji);
  }

  @override
  bool operator ==(Object o) => o is BillReminderAdapter;
  @override
  int get hashCode => typeId;
}
