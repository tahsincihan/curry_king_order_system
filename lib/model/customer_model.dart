import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Customer extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  List<CustomerAddress> addresses;

  @HiveField(4)
  DateTime lastOrderDate;

  @HiveField(5)
  int totalOrders;

  @HiveField(6)
  double totalSpent;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.addresses = const [],
    required this.lastOrderDate,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
  });

  // Helper method to get the most recent address
  CustomerAddress? get mostRecentAddress {
    if (addresses.isEmpty) return null;
    return addresses.reduce((a, b) => a.lastUsed.isAfter(b.lastUsed) ? a : b);
  }

  // Helper method to get last 4 digits of phone
  String get phoneLastFour {
    if (phoneNumber.length >= 4) {
      return phoneNumber.substring(phoneNumber.length - 4);
    }
    return phoneNumber;
  }

  // Helper method to format display name
  String get displayName {
    return '$name (${phoneLastFour})';
  }

  // Add or update an address
  void addOrUpdateAddress(String address, String postcode) {
    // Check if this address already exists
    final existingIndex = addresses.indexWhere((addr) =>
        addr.address.toLowerCase() == address.toLowerCase() &&
        addr.postcode.toLowerCase() == postcode.toLowerCase());

    if (existingIndex != -1) {
      // Update existing address
      addresses[existingIndex].lastUsed = DateTime.now();
      addresses[existingIndex].useCount++;
    } else {
      // Add new address
      addresses.add(CustomerAddress(
        address: address,
        postcode: postcode,
        lastUsed: DateTime.now(),
        useCount: 1,
      ));
    }

    // Keep only the 3 most recent addresses to avoid clutter
    if (addresses.length > 3) {
      addresses.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      addresses = addresses.take(3).toList();
    }
  }

  // Update order statistics
  void updateOrderStats(double orderAmount) {
    totalOrders++;
    totalSpent += orderAmount;
    lastOrderDate = DateTime.now();
  }
}

@HiveType(typeId: 3)
class CustomerAddress extends HiveObject {
  @HiveField(0)
  String address;

  @HiveField(1)
  String postcode;

  @HiveField(2)
  DateTime lastUsed;

  @HiveField(3)
  int useCount;

  CustomerAddress({
    required this.address,
    required this.postcode,
    required this.lastUsed,
    this.useCount = 1,
  });

  String get displayAddress {
    return '$address, $postcode';
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
      addresses: (fields[3] as List?)?.cast<CustomerAddress>() ?? [],
      lastOrderDate: fields[4] as DateTime,
      totalOrders: fields[5] as int? ?? 0,
      totalSpent: fields[6] as double? ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.addresses)
      ..writeByte(4)
      ..write(obj.lastOrderDate)
      ..writeByte(5)
      ..write(obj.totalOrders)
      ..writeByte(6)
      ..write(obj.totalSpent);
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

// Manual Adapter for CustomerAddress
class CustomerAddressAdapter extends TypeAdapter<CustomerAddress> {
  @override
  final int typeId = 3;

  @override
  CustomerAddress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerAddress(
      address: fields[0] as String,
      postcode: fields[1] as String,
      lastUsed: fields[2] as DateTime,
      useCount: fields[3] as int? ?? 1,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerAddress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.address)
      ..writeByte(1)
      ..write(obj.postcode)
      ..writeByte(2)
      ..write(obj.lastUsed)
      ..writeByte(3)
      ..write(obj.useCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAddressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
