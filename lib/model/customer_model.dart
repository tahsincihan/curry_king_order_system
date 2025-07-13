
import 'package:hive/hive.dart';
import 'order_model.dart';

@HiveType(typeId: 2)
class Customer extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  List<String> addresses; // Multiple addresses for same customer

  @HiveField(4)
  String? postcode;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime lastUsed;

  @HiveField(7)
  int orderCount; // How many times this customer has ordered

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.addresses,
    this.postcode,
    required this.createdAt,
    required this.lastUsed,
    this.orderCount = 0,
  });

  // Helper getters
  String get primaryAddress => addresses.isNotEmpty ? addresses.first : '';
  String get phoneLastFour => phoneNumber.length >= 4 ? phoneNumber.substring(phoneNumber.length - 4) : phoneNumber;
  
  // Search helpers
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           phoneNumber.contains(query) ||
           phoneLastFour.contains(query);
  }

  // Update last used time and increment order count
  void recordOrder() {
    lastUsed = DateTime.now();
    orderCount++;
    save(); // Save to Hive
  }

  // Add a new address if it doesn't exist
  void addAddress(String address) {
    if (!addresses.contains(address)) {
      addresses.add(address);
      save();
    }
  }

  // Create from CustomerInfo (from order)
  static Customer fromCustomerInfo(CustomerInfo customerInfo) {
    final now = DateTime.now();
    return Customer(
      id: '${customerInfo.name?.replaceAll(' ', '_').toLowerCase()}_${customerInfo.phoneNumber}',
      name: customerInfo.name ?? '',
      phoneNumber: customerInfo.phoneNumber ?? '',
      addresses: customerInfo.address != null ? [customerInfo.address!] : [],
      postcode: customerInfo.postcode,
      createdAt: now,
      lastUsed: now,
      orderCount: 1,
    );
  }

  // Convert to CustomerInfo for orders
  CustomerInfo toCustomerInfo({String? selectedAddress, bool isDelivery = false}) {
    return CustomerInfo(
      name: name,
      phoneNumber: phoneNumber,
      address: selectedAddress ?? primaryAddress,
      postcode: postcode,
      isDelivery: isDelivery,
    );
  }
}

// Manual Adapter for Customer
class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 2;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      phoneNumber: fields[2] as String,
      addresses: (fields[3] as List?)?.cast<String>() ?? [],
      postcode: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      lastUsed: fields[6] as DateTime,
      orderCount: fields[7] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.addresses)
      ..writeByte(4)
      ..write(obj.postcode)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastUsed)
      ..writeByte(7)
      ..write(obj.orderCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}