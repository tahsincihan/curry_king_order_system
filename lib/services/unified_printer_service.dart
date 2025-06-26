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

  static UnifiedPrinter? getCurrentPrinter() {
    return _selectedPrinter;
  }

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
          type: PrinterType.network,
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

  static Future<UnifiedPrinter?> addNetworkPrinterByIp(String ip) async {
    try {
      final printerUrl = ip;
      final printerName = 'Net Printer at $ip';

      final newPrinter = UnifiedPrinter(
        name: printerName,
        identifier: printerUrl,
        type: PrinterType.network,
        originalPrinter: Printer(url: printerUrl, name: printerName),
      );

      return newPrinter;
    } catch (e) {
      print('Error adding network printer by IP: $e');
      return null;
    }
  }

  // Connect to selected printer
  static Future<bool> connectToPrinter(UnifiedPrinter printer) async {
    try {
      _selectedPrinter = printer;

      if (printer.type == PrinterType.bluetooth) {
        await bluetoothPrint
            .connect(printer.originalPrinter as BluetoothDevice);
      }

      return true;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  static Future<void> disconnect() async {
    if (_selectedPrinter != null) {
      if (_selectedPrinter!.type == PrinterType.bluetooth) {
        await bluetoothPrint.disconnect();
      }
      _selectedPrinter = null;
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

  // **UPDATED: Print via Bluetooth with new layout**
  static Future<void> _printViaBluetooth(Order order) async {
    bool isConnected = await bluetoothPrint.isConnected ?? false;
    if (!isConnected) {
      throw Exception('Bluetooth printer not connected');
    }

    Map<String, dynamic> config = {};
    // Use the new method to generate a text-based receipt
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

              ...order.items.map((item) {
                String mainItemName = item.menuItem.name;
                String? riceModifier;

                if (mainItemName.contains(' with ')) {
                  var parts = mainItemName.split(' with ');
                  mainItemName = parts[0];
                  riceModifier = parts.length > 1 ? parts[1] : null;
                }

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item.quantity}x $mainItemName',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Text(
                          '£${item.totalPrice.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    if (riceModifier != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, top: 2),
                        child: pw.Text(
                          '+ $riceModifier',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                      ),
                    if (item.specialInstructions?.isNotEmpty == true)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 16, top: 4),
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.yellow50,
                            borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'Note: ${item.specialInstructions}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontStyle: pw.FontStyle.italic,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 8),
                  ],
                );
              }).toList(),

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

  // **UPDATED: Generate thermal printer friendly text receipt**
  static List<LineText> _generateBluetoothReceipt(Order order) {
    List<LineText> lines = [];

    // Header
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'CURRY KING',
        weight: 2,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'INDIAN CUISINE',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '================================',
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // Order Info
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: order.orderType.toUpperCase(),
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Date: ${_formatDateTime(order.orderTime)}',
        align: LineText.ALIGN_LEFT,
        linefeed: 1));

    // Customer Info
    if (order.orderType == 'takeaway') {
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'CUSTOMER: ${order.customerInfo.name ?? 'N/A'}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content:
              'TYPE: ${order.customerInfo.isDelivery ? 'DELIVERY' : 'COLLECTION'}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
      if (order.customerInfo.isDelivery) {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'ADDRESS: ${order.customerInfo.address ?? 'N/A'}',
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'POSTCODE: ${order.customerInfo.postcode ?? 'N/A'}',
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
      }
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'PHONE: ${order.customerInfo.phoneNumber ?? 'N/A'}',
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
    } else {
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'TABLE: ${order.tableNumber ?? 'N/A'}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
    }

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // Order Items
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'ORDER ITEMS',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    for (var item in order.items) {
      String mainItemName = item.menuItem.name;
      String? riceModifier;

      if (mainItemName.contains(' with ')) {
        var parts = mainItemName.split(' with ');
        mainItemName = parts[0];
        riceModifier = parts.length > 1 ? parts[1] : null;
      }

      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '${item.quantity}x $mainItemName',
          weight: 1,
          align: LineText.ALIGN_LEFT));
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '£${item.totalPrice.toStringAsFixed(2)}',
          align: LineText.ALIGN_RIGHT,
          linefeed: 1));

      if (riceModifier != null) {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: '  + $riceModifier',
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
      }

      if (item.specialInstructions?.isNotEmpty == true) {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: '********************************',
            align: LineText.ALIGN_CENTER,
            linefeed: 1));
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'NOTE: ${item.specialInstructions}',
            weight: 1,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: '********************************',
            align: LineText.ALIGN_CENTER,
            linefeed: 1));
      }
    }

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // Totals
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Subtotal: £${order.subtotal.toStringAsFixed(2)}',
        align: LineText.ALIGN_RIGHT,
        linefeed: 1));
    if (order.deliveryCharge > 0) {
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Delivery: £${order.deliveryCharge.toStringAsFixed(2)}',
          align: LineText.ALIGN_RIGHT,
          linefeed: 1));
    }
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'TOTAL: £${order.total.toStringAsFixed(2)}',
        weight: 2,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1));

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Payment: ${order.paymentMethod.toUpperCase()}',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 2));

    // Footer
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Thank you for your order!',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '',
        linefeed: 3)); // Add space for cutting

    return lines;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
