import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import '../Model/order_model.dart';


class PrinterService {
  static BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  static BluetoothDevice? _connectedDevice;

  static Future<List<BluetoothDevice>> getAvailablePrinters() async {
    List<BluetoothDevice> devices = [];
    try {
      // Start scanning for devices
      bluetoothPrint.startScan(timeout: Duration(seconds: 4));
      
      // Listen for scan results
      bluetoothPrint.scanResults.listen((devices) {
        // Filter for printers (you might want to filter by device name or type)
        return devices.where((device) => 
          device.name != null && 
          (device.name!.toLowerCase().contains('printer') ||
           device.name!.toLowerCase().contains('pos') ||
           device.name!.toLowerCase().contains('receipt'))
        ).toList();
      });
      
      await Future.delayed(Duration(seconds: 5));
      bluetoothPrint.stopScan();
    } catch (e) {
      print('Error scanning for printers: $e');
    }
    return devices;
  }

  static Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      await bluetoothPrint.connect(device);
      _connectedDevice = device;
      return true;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  static Future<void> disconnectPrinter() async {
    try {
      if (_connectedDevice != null) {
        await bluetoothPrint.disconnect();
        _connectedDevice = null;
      }
    } catch (e) {
      print('Error disconnecting printer: $e');
    }
  }

  static Future<void> printOrder(Order order) async {
    try {
      // Check if connected to a printer
      bool isConnected = await bluetoothPrint.isConnected ?? false;
      
      if (!isConnected) {
        throw Exception('No printer connected. Please connect to a Bluetooth printer first.');
      }

      // Generate receipt content
      List<LineText> receiptLines = _generateReceiptContent(order);
      
      // Print the receipt
      await bluetoothPrint.printReceipt(receiptLines);
      
    } catch (e) {
      print('Error printing order: $e');
      throw e;
    }
  }

  static List<LineText> _generateReceiptContent(Order order) {
    List<LineText> lines = [];
    
    // Header
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '================================',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'CURRY KING',
      weight: 2,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'INDIAN CUISINE',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '================================',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 2,
    ));

    // Order Type and Time
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: order.orderType == 'takeaway' ? 'TAKEAWAY ORDER' : 'DINE IN ORDER',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Date: ${_formatDateTime(order.orderTime)}',
      weight: 0,
      align: LineText.ALIGN_LEFT,
      linefeed: 2,
    ));

    // Customer/Table Information
    if (order.orderType == 'takeaway') {
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'CUSTOMER DETAILS',
        weight: 1,
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
      
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Name: ${order.customerInfo.name ?? 'N/A'}',
        weight: 0,
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
      
      if (order.customerInfo.isDelivery) {
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Type: DELIVERY',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
        
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Address: ${order.customerInfo.address ?? 'N/A'}',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
        
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Postcode: ${order.customerInfo.postcode ?? 'N/A'}',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
        
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Phone: ${order.customerInfo.phoneNumber ?? 'N/A'}',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      } else {
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Type: COLLECTION',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
        
        if (order.customerInfo.phoneNumber?.isNotEmpty == true) {
          lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Phone: ${order.customerInfo.phoneNumber}',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1,
          ));
        }
      }
    } else {
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Table: ${order.tableNumber ?? 'N/A'}',
        weight: 1,
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
    }
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--------------------------------',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    // Order Items
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'ORDER ITEMS',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--------------------------------',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));

    for (OrderItem item in order.items) {
      // Item name and quantity
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '${item.quantity}x ${item.menuItem.name}',
        weight: 0,
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
      
      // Unit price and total
      String priceString = '£${item.menuItem.price.toStringAsFixed(2)} each';
      String totalString = '£${item.totalPrice.toStringAsFixed(2)}';
      
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '$priceString $totalString',
        weight: 0,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1,
      ));
      
      // Special instructions
      if (item.specialInstructions?.isNotEmpty == true) {
        lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Note: ${item.specialInstructions}',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ));
      }
      
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '',
        weight: 0,
        align: LineText.ALIGN_LEFT,
        linefeed: 1,
      ));
    }

    // Totals
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--------------------------------',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Subtotal: £${order.subtotal.toStringAsFixed(2)}',
      weight: 0,
      align: LineText.ALIGN_RIGHT,
      linefeed: 1,
    ));
    
    if (order.deliveryCharge > 0) {
      lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Delivery: £${order.deliveryCharge.toStringAsFixed(2)}',
        weight: 0,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1,
      ));
    }
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '--------------------------------',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'TOTAL: £${order.total.toStringAsFixed(2)}',
      weight: 2,
      align: LineText.ALIGN_RIGHT,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Payment: ${order.paymentMethod.toUpperCase()}',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 2,
    ));

    // Footer
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '================================',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'Thank you for your order!',
      weight: 1,
      align: LineText.ALIGN_CENTER,
      linefeed: 1,
    ));
    
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: 'CURRY KING - INDIAN CUISINE',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 2,
    ));
    
    // Cut paper
    lines.add(LineText(
      type: LineText.TYPE_TEXT,
      content: '',
      weight: 0,
      align: LineText.ALIGN_CENTER,
      linefeed: 3,
    ));

    return lines;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Method to show printer selection dialog
  static Future<void> showPrinterSelectionDialog(context) async {
    List<BluetoothDevice> devices = await getAvailablePrinters();
    
    if (devices.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('No Printers Found'),
            content: Text('No Bluetooth printers were found. Please make sure your printer is turned on and in pairing mode.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Printer'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(devices[index].name ?? 'Unknown Device'),
                  subtitle: Text(devices[index].address ?? ''),
                  onTap: () async {
                    Navigator.of(context).pop();
                    bool connected = await connectToPrinter(devices[index]);
                    if (connected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Connected to ${devices[index].name}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to connect to printer')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}