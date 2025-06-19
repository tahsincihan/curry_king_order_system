import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class DailySales extends HiveObject {
  @HiveField(0)
  String date; // Format: yyyy-MM-dd

  @HiveField(1)
  double cashSales;

  @HiveField(2)
  double cardSales;

  @HiveField(3)
  int totalOrders;

  @HiveField(4)
  int cashOrders;

  @HiveField(5)
  int cardOrders;

  @HiveField(6)
  double deliveryCharges;

  @HiveField(7)
  List<SaleTransaction> transactions;

  DailySales({
    required this.date,
    this.cashSales = 0.0,
    this.cardSales = 0.0,
    this.totalOrders = 0,
    this.cashOrders = 0,
    this.cardOrders = 0,
    this.deliveryCharges = 0.0,
    this.transactions = const [],
  });

  double get totalSales => cashSales + cardSales;
  
  void addTransaction(SaleTransaction transaction) {
    transactions = [...transactions, transaction];
    
    if (transaction.paymentMethod == 'cash') {
      cashSales += transaction.amount;
      cashOrders++;
    } else {
      cardSales += transaction.amount;
      cardOrders++;
    }
    
    totalOrders++;
    deliveryCharges += transaction.deliveryCharge;
  }
}

@HiveType(typeId: 1)
class SaleTransaction extends HiveObject {
  @HiveField(0)
  String orderId;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String paymentMethod; // 'cash' or 'card'

  @HiveField(4)
  String orderType; // 'takeaway' or 'dine-in'

  @HiveField(5)
  double deliveryCharge;

  @HiveField(6)
  int itemCount;

  @HiveField(7)
  String? customerName;

  @HiveField(8)
  String? tableNumber;

  SaleTransaction({
    required this.orderId,
    required this.timestamp,
    required this.amount,
    required this.paymentMethod,
    required this.orderType,
    this.deliveryCharge = 0.0,
    this.itemCount = 0,
    this.customerName,
    this.tableNumber,
  });
}

// Manual Adapter for DailySales
class DailySalesAdapter extends TypeAdapter<DailySales> {
  @override
  final int typeId = 0;

  @override
  DailySales read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailySales(
      date: fields[0] as String,
      cashSales: fields[1] as double? ?? 0.0,
      cardSales: fields[2] as double? ?? 0.0,
      totalOrders: fields[3] as int? ?? 0,
      cashOrders: fields[4] as int? ?? 0,
      cardOrders: fields[5] as int? ?? 0,
      deliveryCharges: fields[6] as double? ?? 0.0,
      transactions: (fields[7] as List?)?.cast<SaleTransaction>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, DailySales obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.cashSales)
      ..writeByte(2)
      ..write(obj.cardSales)
      ..writeByte(3)
      ..write(obj.totalOrders)
      ..writeByte(4)
      ..write(obj.cashOrders)
      ..writeByte(5)
      ..write(obj.cardOrders)
      ..writeByte(6)
      ..write(obj.deliveryCharges)
      ..writeByte(7)
      ..write(obj.transactions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySalesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// Manual Adapter for SaleTransaction
class SaleTransactionAdapter extends TypeAdapter<SaleTransaction> {
  @override
  final int typeId = 1;

  @override
  SaleTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleTransaction(
      orderId: fields[0] as String,
      timestamp: fields[1] as DateTime,
      amount: fields[2] as double,
      paymentMethod: fields[3] as String,
      orderType: fields[4] as String,
      deliveryCharge: fields[5] as double? ?? 0.0,
      itemCount: fields[6] as int? ?? 0,
      customerName: fields[7] as String?,
      tableNumber: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleTransaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paymentMethod)
      ..writeByte(4)
      ..write(obj.orderType)
      ..writeByte(5)
      ..write(obj.deliveryCharge)
      ..writeByte(6)
      ..write(obj.itemCount)
      ..writeByte(7)
      ..write(obj.customerName)
      ..writeByte(8)
      ..write(obj.tableNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}