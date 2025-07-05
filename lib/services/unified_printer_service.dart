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
      name: 'Order_${order.id}',
    );
  }

  // Print via Bluetooth with updated compact layout
  static Future<void> _printViaBluetooth(Order order) async {
    bool isConnected = await bluetoothPrint.isConnected ?? false;
    if (!isConnected) {
      throw Exception('Bluetooth printer not connected');
    }

    Map<String, dynamic> config = {};
    List<LineText> receiptLines = _generateBluetoothReceipt(order);
    await bluetoothPrint.printReceipt(config, receiptLines);
  }

  // **UPDATED COMPACT PDF GENERATION**
  static Future<Uint8List> _generateReceiptPDF(Order order) async {
    final pdf = pw.Document();
    final orderId = order.id.substring(order.id.length - 5);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Compact Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CURRY KING',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      width: double.infinity,
                      height: 0.5,
                      color: PdfColors.black,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 4),

              // Order info in one line
              pw.Text(
                'Order #$orderId',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Date: ${_formatDateTime(order.orderTime)}',
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 2),
              pw.Container(
                  width: double.infinity, height: 0.5, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // ORDER ITEMS header
              pw.Text(
                'ORDER ITEMS',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),

              // Compact item list
              ...order.items.map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${item.quantity}x ${item.menuItem.name}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.Text(
                            '£${item.totalPrice.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      if (item.specialInstructions?.isNotEmpty == true)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 8, top: 1),
                          child: pw.Text(
                            'Note: ${item.specialInstructions}',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 4),
              pw.Container(
                  width: double.infinity, height: 0.5, color: PdfColors.black),
              pw.SizedBox(height: 2),

              // Compact totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('£${order.subtotal.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (order.deliveryCharge > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Delivery:',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('£${order.deliveryCharge.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),

              pw.SizedBox(height: 2),
              pw.Container(
                  width: double.infinity, height: 0.5, color: PdfColors.black),
              pw.SizedBox(height: 2),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '£${order.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),
              pw.Container(
                  width: double.infinity, height: 0.5, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Compact customer details
              if (order.orderType == 'takeaway') ...[
                pw.Text(
                  'CUSTOMER DETAILS',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Name: ${order.customerInfo.name ?? 'N/A'}',
                    style: const pw.TextStyle(fontSize: 10)),
                if (order.customerInfo.isDelivery) ...[
                  pw.Text('Type: DELIVERY',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Address: ${order.customerInfo.address ?? 'N/A'}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Postcode: ${order.customerInfo.postcode ?? 'N/A'}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Phone: ${order.customerInfo.phoneNumber ?? 'N/A'}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                      'Status: ${order.paymentMethod == 'none' ? 'Paid' : order.paymentMethod.toUpperCase()}',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ] else ...[
                  pw.Text('Type: DELIVERY',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  if (order.customerInfo.phoneNumber?.isNotEmpty == true)
                    pw.Text('Phone: ${order.customerInfo.phoneNumber}',
                        style: const pw.TextStyle(fontSize: 9)),
                ],
              ] else ...[
                pw.Text('Table Number: ${order.tableNumber ?? 'N/A'}',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // **UPDATED COMPACT BLUETOOTH RECEIPT**
  static List<LineText> _generateBluetoothReceipt(Order order) {
    List<LineText> lines = [];
    final orderId = order.id.substring(order.id.length - 5);

    // Compact Header
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'CURRY KING',
        weight: 1,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '================================',
        weight: 0,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // Order info
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Order #$orderId',
        weight: 1,
        align: LineText.ALIGN_LEFT,
        linefeed: 1));

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Date: ${_formatDateTime(order.orderTime)}',
        weight: 0,
        align: LineText.ALIGN_LEFT,
        linefeed: 1));

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        weight: 0,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // ORDER ITEMS
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'ORDER ITEMS',
        weight: 1,
        align: LineText.ALIGN_LEFT,
        linefeed: 1));

    // Compact item listing with better formatting for thermal printers
    for (var item in order.items) {
      // Split long item names to fit thermal printer width
      String itemName = item.menuItem.name;
      String itemLine = '${item.quantity}x $itemName';

      // For thermal printers, try to keep lines under 32 characters
      if (itemLine.length > 32) {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: '${item.quantity}x',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));

        // Split long names into multiple lines if needed
        if (itemName.length > 28) {
          List<String> words = itemName.split(' ');
          String currentLine = '';

          for (String word in words) {
            if ((currentLine + word).length > 28) {
              if (currentLine.isNotEmpty) {
                lines.add(LineText(
                    type: LineText.TYPE_TEXT,
                    content: '  $currentLine',
                    weight: 0,
                    align: LineText.ALIGN_LEFT,
                    linefeed: 1));
                currentLine = word;
              } else {
                lines.add(LineText(
                    type: LineText.TYPE_TEXT,
                    content: '  $word',
                    weight: 0,
                    align: LineText.ALIGN_LEFT,
                    linefeed: 1));
              }
            } else {
              currentLine += (currentLine.isEmpty ? '' : ' ') + word;
            }
          }
          if (currentLine.isNotEmpty) {
            lines.add(LineText(
                type: LineText.TYPE_TEXT,
                content: '  $currentLine',
                weight: 0,
                align: LineText.ALIGN_LEFT,
                linefeed: 1));
          }
        } else {
          lines.add(LineText(
              type: LineText.TYPE_TEXT,
              content: '  $itemName',
              weight: 0,
              align: LineText.ALIGN_LEFT,
              linefeed: 1));
        }
      } else {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: itemLine,
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
      }

      // Price on separate line, right aligned
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: '£${item.totalPrice.toStringAsFixed(2)}',
          weight: 0,
          align: LineText.ALIGN_RIGHT,
          linefeed: 1));

      if (item.specialInstructions?.isNotEmpty == true) {
        // Break special instructions into smaller lines
        String instructions = 'NOTE: ${item.specialInstructions}';
        if (instructions.length > 32) {
          List<String> words = instructions.split(' ');
          String currentLine = '';

          for (String word in words) {
            if ((currentLine + word).length > 32) {
              if (currentLine.isNotEmpty) {
                lines.add(LineText(
                    type: LineText.TYPE_TEXT,
                    content: currentLine,
                    weight: 1,
                    align: LineText.ALIGN_LEFT,
                    linefeed: 1));
                currentLine = word;
              } else {
                lines.add(LineText(
                    type: LineText.TYPE_TEXT,
                    content: word,
                    weight: 1,
                    align: LineText.ALIGN_LEFT,
                    linefeed: 1));
              }
            } else {
              currentLine += (currentLine.isEmpty ? '' : ' ') + word;
            }
          }
          if (currentLine.isNotEmpty) {
            lines.add(LineText(
                type: LineText.TYPE_TEXT,
                content: currentLine,
                weight: 1,
                align: LineText.ALIGN_LEFT,
                linefeed: 1));
          }
        } else {
          lines.add(LineText(
              type: LineText.TYPE_TEXT,
              content: instructions,
              weight: 1,
              align: LineText.ALIGN_LEFT,
              linefeed: 1));
        }
      }

      // Add small space between items
      lines.add(LineText(type: LineText.TYPE_TEXT, content: '', linefeed: 1));
    }

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        weight: 0,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // Totals
    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'Subtotal: £${order.subtotal.toStringAsFixed(2)}',
        weight: 0,
        align: LineText.ALIGN_RIGHT,
        linefeed: 1));

    if (order.deliveryCharge > 0) {
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Delivery: £${order.deliveryCharge.toStringAsFixed(2)}',
          weight: 0,
          align: LineText.ALIGN_RIGHT,
          linefeed: 1));
    }

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        weight: 0,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: 'TOTAL: £${order.total.toStringAsFixed(2)}',
        weight: 2,
        align: LineText.ALIGN_RIGHT,
        linefeed: 2));

    lines.add(LineText(
        type: LineText.TYPE_TEXT,
        content: '--------------------------------',
        weight: 0,
        align: LineText.ALIGN_CENTER,
        linefeed: 1));

    // Customer details with proper line breaking
    if (order.orderType == 'takeaway') {
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'CUSTOMER DETAILS',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));

      String customerName = order.customerInfo.name ?? 'N/A';
      if (customerName.length > 25) {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Name:',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: customerName,
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
      } else {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Name: $customerName',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
      }

      if (order.customerInfo.isDelivery) {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Type: DELIVERY',
            weight: 1,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));

        String address = order.customerInfo.address ?? 'N/A';
        if (address.length > 25) {
          lines.add(LineText(
              type: LineText.TYPE_TEXT,
              content: 'Address:',
              weight: 0,
              align: LineText.ALIGN_LEFT,
              linefeed: 1));

          // Break address into multiple lines
          List<String> words = address.split(' ');
          String currentLine = '';

          for (String word in words) {
            if ((currentLine + word).length > 30) {
              if (currentLine.isNotEmpty) {
                lines.add(LineText(
                    type: LineText.TYPE_TEXT,
                    content: currentLine,
                    weight: 0,
                    align: LineText.ALIGN_LEFT,
                    linefeed: 1));
                currentLine = word;
              } else {
                lines.add(LineText(
                    type: LineText.TYPE_TEXT,
                    content: word,
                    weight: 0,
                    align: LineText.ALIGN_LEFT,
                    linefeed: 1));
              }
            } else {
              currentLine += (currentLine.isEmpty ? '' : ' ') + word;
            }
          }
          if (currentLine.isNotEmpty) {
            lines.add(LineText(
                type: LineText.TYPE_TEXT,
                content: currentLine,
                weight: 0,
                align: LineText.ALIGN_LEFT,
                linefeed: 1));
          }
        } else {
          lines.add(LineText(
              type: LineText.TYPE_TEXT,
              content: 'Address: $address',
              weight: 0,
              align: LineText.ALIGN_LEFT,
              linefeed: 1));
        }

        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Postcode: ${order.customerInfo.postcode ?? 'N/A'}',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));

        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Phone: ${order.customerInfo.phoneNumber ?? 'N/A'}',
            weight: 0,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));

        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content:
                'Status: ${order.paymentMethod == 'none' ? 'Paid' : order.paymentMethod.toUpperCase()}',
            weight: 1,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));
      } else {
        lines.add(LineText(
            type: LineText.TYPE_TEXT,
            content: 'Type: COLLECTION',
            weight: 1,
            align: LineText.ALIGN_LEFT,
            linefeed: 1));

        if (order.customerInfo.phoneNumber?.isNotEmpty == true) {
          lines.add(LineText(
              type: LineText.TYPE_TEXT,
              content: 'Phone: ${order.customerInfo.phoneNumber}',
              weight: 0,
              align: LineText.ALIGN_LEFT,
              linefeed: 1));
        }
      }
    } else {
      lines.add(LineText(
          type: LineText.TYPE_TEXT,
          content: 'Table: ${order.tableNumber ?? 'N/A'}',
          weight: 1,
          align: LineText.ALIGN_LEFT,
          linefeed: 1));
    }

    // Add some space at the end
    lines.add(LineText(type: LineText.TYPE_TEXT, content: '', linefeed: 3));

    return lines;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
