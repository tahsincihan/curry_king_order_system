import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import '../model/order_model.dart';
import 'dart:typed_data';
import 'dart:io';

enum PrinterType { bluetooth, network, usb }

class UnifiedPrinter {
  final String name;
  final String identifier; // IP address for network, MAC for Bluetooth
  final PrinterType type;
  final dynamic originalPrinter; // Store original printer object

  UnifiedPrinter({
    required this.name,
    required this.identifier,
    required this.type,
    this.originalPrinter,
  });
}

class UnifiedPrinterService {
  static BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  static UnifiedPrinter? _selectedPrinter;

  // Get all available printers (Bluetooth + Network)
  static Future<List<UnifiedPrinter>> getAllAvailablePrinters() async {
    List<UnifiedPrinter> allPrinters = [];

    // Get network/WiFi printers
    try {
      final networkPrinters = await Printing.listPrinters();
      for (var printer in networkPrinters) {
        allPrinters.add(UnifiedPrinter(
          name: printer.name,
          identifier: printer.url,
          type: printer.url.startsWith('tcp://')
              ? PrinterType.network
              : PrinterType.usb,
          originalPrinter: printer,
        ));
      }
    } catch (e) {
      print('Error getting network printers: $e');
    }

    // Get Bluetooth printers (mobile only)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        bluetoothPrint.startScan(timeout: const Duration(seconds: 4));
        await Future.delayed(const Duration(seconds: 5));

        List<BluetoothDevice> devices = [];
        bluetoothPrint.scanResults.listen((scanResults) {
          devices = scanResults;
        });

        await Future.delayed(const Duration(seconds: 1));
        bluetoothPrint.stopScan();

        for (var device in devices) {
          if (device.name != null) {
            allPrinters.add(UnifiedPrinter(
              name: device.name!,
              identifier: device.address ?? '',
              type: PrinterType.bluetooth,
              originalPrinter: device,
            ));
          }
        }
      } catch (e) {
        print('Error getting Bluetooth printers: $e');
      }
    }

    return allPrinters;
  }

  // Connect to selected printer
  static Future<bool> connectToPrinter(UnifiedPrinter printer) async {
    try {
      _selectedPrinter = printer;

      if (printer.type == PrinterType.bluetooth) {
        await bluetoothPrint
            .connect(printer.originalPrinter as BluetoothDevice);
      }
      // Network printers don't need explicit connection

      return true;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  // Print order
  static Future<void> printOrder(Order order) async {
    if (_selectedPrinter == null) {
      throw Exception('No printer selected');
    }

    if (_selectedPrinter!.type == PrinterType.bluetooth) {
      await _printViaBluetooth(order);
    } else {
      await _printViaNetwork(order);
    }
  }

  // Print via network/WiFi
  static Future<void> _printViaNetwork(Order order) async {
    final pdf = await _generateReceiptPDF(order);

    await Printing.directPrintPdf(
      printer: _selectedPrinter!.originalPrinter as Printer,
      onLayout: (format) => pdf,
      format: PdfPageFormat.roll80,
      name: 'Order_${order.orderTime.millisecondsSinceEpoch}',
    );
  }

  // Print via Bluetooth (existing implementation)
  static Future<void> _printViaBluetooth(Order order) async {
    bool isConnected = await bluetoothPrint.isConnected ?? false;
    if (!isConnected) {
      throw Exception('Bluetooth printer not connected');
    }

    Map<String, dynamic> config = {};
    List<LineText> receiptLines = _generateBluetoothReceipt(order);
    await bluetoothPrint.printReceipt(config, receiptLines);
  }

  // Generate PDF for network printing
  static Future<Uint8List> _generateReceiptPDF(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CURRY KING',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'INDIAN CUISINE',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Divider(),
                  ],
                ),
              ),

              // Order Type
              pw.Text(
                order.orderType == 'takeaway'
                    ? 'TAKEAWAY ORDER'
                    : 'DINE IN ORDER',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Date: ${_formatDateTime(order.orderTime)}'),
              pw.SizedBox(height: 8),

              // Customer/Table Info
              if (order.orderType == 'takeaway') ...[
                pw.Text(
                  'CUSTOMER DETAILS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Name: ${order.customerInfo.name ?? 'N/A'}'),
                if (order.customerInfo.isDelivery) ...[
                  pw.Text('Type: DELIVERY'),
                  pw.Text('Address: ${order.customerInfo.address ?? 'N/A'}'),
                  pw.Text('Postcode: ${order.customerInfo.postcode ?? 'N/A'}'),
                  pw.Text('Phone: ${order.customerInfo.phoneNumber ?? 'N/A'}'),
                ] else ...[
                  pw.Text('Type: COLLECTION'),
                  if (order.customerInfo.phoneNumber?.isNotEmpty == true)
                    pw.Text('Phone: ${order.customerInfo.phoneNumber}'),
                ],
              ] else ...[
                pw.Text('Table: ${order.tableNumber ?? 'N/A'}'),
              ],

              pw.Divider(),

              // Order Items
              pw.Text(
                'ORDER ITEMS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),

              ...order.items
                  .map((item) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                    '${item.quantity}x ${item.menuItem.name}'),
                              ),
                              pw.Text('£${item.totalPrice.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (item.specialInstructions?.isNotEmpty == true)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 16),
                              child: pw.Text(
                                'Note: ${item.specialInstructions}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                          pw.SizedBox(height: 4),
                        ],
                      ))
                  .toList(),

              pw.Divider(),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('£${order.subtotal.toStringAsFixed(2)}'),
                ],
              ),

              if (order.deliveryCharge > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Delivery:'),
                    pw.Text('£${order.deliveryCharge.toStringAsFixed(2)}'),
                  ],
                ),

              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '£${order.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Payment: ${order.paymentMethod.toUpperCase()}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your order!',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('CURRY KING - INDIAN CUISINE'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Generate Bluetooth receipt (existing implementation)
  static List<LineText> _generateBluetoothReceipt(Order order) {
    // Use your existing Bluetooth receipt generation code here
    List<LineText> lines = [];
    // ... (copy from your existing printer_service.dart)
    return lines;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
