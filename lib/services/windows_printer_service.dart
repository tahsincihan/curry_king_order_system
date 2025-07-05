import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../model/order_model.dart';

class WindowsPrinterService {
  static String? _selectedPrinter;
  static List<Printer> _availablePrinters = [];

  // Get available system printers
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      _availablePrinters = await Printing.listPrinters();
      return _availablePrinters;
    } catch (e) {
      print('Error getting printers: $e');
      return [];
    }
  }

  // Set default printer
  static void setDefaultPrinter(String printerName) {
    _selectedPrinter = printerName;
  }

  // Get current printer
  static String? getCurrentPrinter() {
    return _selectedPrinter;
  }

  // Print order using Windows printing system
  static Future<void> printOrder(Order order) async {
    try {
      // Generate PDF for the receipt
      final pdf = await _generateReceiptPDF(order);

      // Print using system printer
      if (_selectedPrinter != null) {
        await Printing.directPrintPdf(
          printer: Printer(url: _selectedPrinter!),
          onLayout: (format) => pdf,
          name: 'Order_${order.orderTime.millisecondsSinceEpoch}',
          format: PdfPageFormat.roll80, // 80mm receipt paper
        );
      } else {
        // Show printer selection dialog
        await Printing.layoutPdf(
          onLayout: (format) => pdf,
          name: 'Curry_King_Order',
          format: PdfPageFormat.roll80,
        );
      }
    } catch (e) {
      print('Error printing order: $e');
      throw Exception('Failed to print order: ${e.toString()}');
    }
  }

  // **UPDATED COMPACT PDF GENERATION MATCHING THE RECEIPT FORMAT**
  static Future<Uint8List> _generateReceiptPDF(Order order) async {
    final pdf = pw.Document();
    final orderId = order.id.substring(order.id.length - 5);
    String orderSubtitle = 'DINE-IN ORDER';
    if (order.orderType == 'takeaway') {
      orderSubtitle =
          order.customerInfo.isDelivery ? 'DELIVERY ORDER' : 'COLLECTION ORDER';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          // Center the content and constrain its width
          return pw.Center(
            child: pw.SizedBox(
              width: 72 * PdfPageFormat.mm, // Constrain content to 72mm width
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Compact Header
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'CURRY KING',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          orderSubtitle,
                          style: pw.TextStyle(
                            fontSize: 11,
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

                  pw.SizedBox(height: 3),

                  // Order info
                  pw.Text(
                    'Order #$orderId',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Date: ${_formatDateTime(order.orderTime)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.SizedBox(height: 2),
                  pw.Container(
                      width: double.infinity,
                      height: 0.5,
                      color: PdfColors.black),
                  pw.SizedBox(height: 3),

                  // ORDER ITEMS header
                  pw.Text(
                    'ORDER ITEMS',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),

                  // Compact item list matching the receipt format
                  ...order.items.map((item) {
                    return pw.Container(
                      margin: const pw.EdgeInsets.symmetric(vertical: 1),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  '${item.quantity}x ${item.menuItem.name}',
                                  style: const pw.TextStyle(fontSize: 9),
                                  maxLines: 2,
                                  overflow: pw.TextOverflow.visible,
                                ),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Text(
                                '£${item.totalPrice.toStringAsFixed(2)}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                          if (item.selectedRice != null &&
                              item.selectedRice != 'Pilau Rice' &&
                              item.selectedRice != 'Plain Rice')
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.only(left: 6, top: 1),
                              child: pw.Text(
                                '+ ${item.selectedRice}',
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                          if (item.specialInstructions?.isNotEmpty == true)
                            pw.Padding(
                              padding:
                                  const pw.EdgeInsets.only(left: 6, top: 1),
                              child: pw.Text(
                                '(${item.specialInstructions})',
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.black,
                                ),
                                maxLines: 2,
                                overflow: pw.TextOverflow.visible,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  pw.SizedBox(height: 3),
                  pw.Container(
                      width: double.infinity,
                      height: 0.5,
                      color: PdfColors.black),
                  pw.SizedBox(height: 2),

                  // Compact totals
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal:',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('£${order.subtotal.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  if (order.deliveryCharge > 0)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Delivery:',
                            style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('£${order.deliveryCharge.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),

                  pw.SizedBox(height: 2),
                  pw.Container(
                      width: double.infinity,
                      height: 0.5,
                      color: PdfColors.black),
                  pw.SizedBox(height: 2),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '£${order.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 3),
                  pw.Container(
                      width: double.infinity,
                      height: 0.5,
                      color: PdfColors.black),
                  pw.SizedBox(height: 3),

                  // Compact customer details matching the receipt format
                  if (order.orderType == 'takeaway') ...[
                    pw.Text(
                      'CUSTOMER DETAILS',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Name: ${order.customerInfo.name ?? 'N/A'}',
                        style: const pw.TextStyle(fontSize: 9)),
                    if (order.customerInfo.isDelivery) ...[
                      pw.Text('Type: DELIVERY',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Address: ${order.customerInfo.address ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 8),
                          maxLines: 2,
                          overflow: pw.TextOverflow.visible),
                      pw.Text(
                          'Postcode: ${order.customerInfo.postcode ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          'Phone: ${order.customerInfo.phoneNumber ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(
                          'Status: ${order.paymentMethod == 'none' ? 'Paid' : order.paymentMethod.toUpperCase()}',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ] else ...[
                      pw.Text('Type: COLLECTION',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if (order.customerInfo.phoneNumber?.isNotEmpty == true)
                        pw.Text('Phone: ${order.customerInfo.phoneNumber}',
                            style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ] else ...[
                    pw.Text('Table Number: ${order.tableNumber ?? 'N/A'}',
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Test print function with compact layout
  static Future<void> testPrint() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.SizedBox(
                width: 72 * PdfPageFormat.mm,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'CURRY KING',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(
                        width: double.infinity,
                        height: 0.5,
                        color: PdfColors.black),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'PRINTER TEST',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text('This is a test print.',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                        'Date: ${DateTime.now().toString().substring(0, 19)}',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 6),
                    pw.Text('Test completed successfully!',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 6),
                    pw.Container(
                        width: double.infinity,
                        height: 0.5,
                        color: PdfColors.black),
                  ],
                ),
              ),
            );
          },
        ),
      );

      if (_selectedPrinter != null) {
        await Printing.directPrintPdf(
          printer: Printer(url: _selectedPrinter!),
          onLayout: (format) => pdf.save(),
          format: PdfPageFormat.roll80,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name: 'Test_Print',
          format: PdfPageFormat.roll80,
        );
      }
    } catch (e) {
      throw Exception('Test print failed: ${e.toString()}');
    }
  }

  // Format date time for receipt
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Show printer selection dialog
  static Future<void> showPrinterSelectionDialog(BuildContext context) async {
    List<Printer> printers = await getAvailablePrinters();

    if (printers.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Printers Found'),
              content: const Text(
                  'No printers were found. Please make sure your printer is connected and try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Printer'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(printers[index].name),
                    subtitle: Text(printers[index].url),
                    onTap: () async {
                      Navigator.of(context).pop();
                      setDefaultPrinter(printers[index].url);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Selected printer: ${printers[index].name}')),
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
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }
}
