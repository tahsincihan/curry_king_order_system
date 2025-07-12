import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class SavedCustomer extends HiveObject {
  @HiveField(0)
  String id; // Unique identifier

  @HiveField(1)
  String name;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  List<SavedAddress> addresses;

  @HiveField(4)
  DateTime lastOrderDate;

  @HiveField(5)
  int totalOrders;

  @HiveField(6)
  String? preferredPaymentMethod;

  SavedCustomer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.addresses = const [],
    required this.lastOrderDate,
    this.totalOrders = 1,
    this.preferredPaymentMethod,
  });

  // Get the most recent address
  SavedAddress? get mostRecentAddress {
    if (addresses.isEmpty) return null;
    addresses.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return addresses.first;
  }

  // Get last 4 digits of phone number for search
  String get phoneLastFour {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 4 ? cleaned.substring(cleaned.length - 4) : cleaned;
  }

  // Add or update an address
  void addOrUpdateAddress(SavedAddress newAddress) {
    // Check if this address already exists
    final existingIndex = addresses.indexWhere((addr) => 
      addr.fullAddress.toLowerCase() == newAddress.fullAddress.toLowerCase() &&
      addr.postcode.toLowerCase() == newAddress.postcode.toLowerCase());

    if (existingIndex >= 0) {
      // Update existing address
      addresses[existingIndex].lastUsed = DateTime.now();
      addresses[existingIndex].timesUsed++;
    } else {
      // Add new address
      addresses.add(newAddress);
    }

    // Keep only the 5 most recent addresses per customer
    addresses.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    if (addresses.length > 5) {
      addresses = addresses.take(5).toList();
    }
  }
}

@HiveType(typeId: 3)
class SavedAddress extends HiveObject {
  @HiveField(0)
  String fullAddress;

  @HiveField(1)
  String postcode;

  @HiveField(2)
  DateTime lastUsed;

  @HiveField(3)
  int timesUsed;

  @HiveField(4)
  String? deliveryInstructions;

  @HiveField(5)
  bool isDefault;

  SavedAddress({
    required this.fullAddress,
    required this.postcode,
    required this.lastUsed,
    this.timesUsed = 1,
    this.deliveryInstructions,
    this.isDefault = false,
  });

  String get displayAddress {
    return '$fullAddress, $postcode';
  }
}

// Manual Hive Adapters
class SavedCustomerAdapter extends TypeAdapter<SavedCustomer> {
  @override
  final int typeId = 2;

  @override
  SavedCustomer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedCustomer(
      id: fields[0] as String,
      name: fields[1] as String,
      phoneNumber: fields[2] as String,
      addresses: (fields[3] as List?)?.cast<SavedAddress>() ?? [],
      lastOrderDate: fields[4] as DateTime,
      totalOrders: fields[5] as int? ?? 1,
      preferredPaymentMethod: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavedCustomer obj) {
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
      ..write(obj.preferredPaymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedCustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavedAddressAdapter extends TypeAdapter<SavedAddress> {
  @override
  final int typeId = 3;

  @override
  SavedAddress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedAddress(
      fullAddress: fields[0] as String,
      postcode: fields[1] as String,
      lastUsed: fields[2] as DateTime,
      timesUsed: fields[3] as int? ?? 1,
      deliveryInstructions: fields[4] as String?,
      isDefault: fields[5] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SavedAddress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.fullAddress)
      ..writeByte(1)
      ..write(obj.postcode)
      ..writeByte(2)
      ..write(obj.lastUsed)
      ..writeByte(3)
      ..write(obj.timesUsed)
      ..writeByte(4)
      ..write(obj.deliveryInstructions)
      ..writeByte(5)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedAddressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}