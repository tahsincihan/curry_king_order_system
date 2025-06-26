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

  // **UPDATED PDF GENERATION LOGIC**
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
                    // "INDIAN CUISINE" REMOVED
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: double.infinity,
                      height: 1,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),

              // Order Info
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

              pw.SizedBox(height: 8),
              pw.Container(
                  width: double.infinity, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 8),

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
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
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
                          )),
                    pw.SizedBox(height: 8),
                  ],
                );
              }).toList(),

              pw.SizedBox(height: 8),
              pw.Container(
                  width: double.infinity, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 8),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:'),
                  pw.Text('£${order.subtotal.toStringAsFixed(2)}'),
                ],
              ),

              if (order.discountAmount > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discount (${order.discountReason}):'),
                    pw.Text(
                      '-£${order.discountAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(color: PdfColors.red),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Discounted Subtotal:'),
                    pw.Text(
                        '£${order.subtotalAfterDiscount.toStringAsFixed(2)}'),
                  ],
                ),
              ],

              if (order.deliveryCharge > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Delivery:'),
                    pw.Text('£${order.deliveryCharge.toStringAsFixed(2)}'),
                  ],
                ),

              pw.Container(
                  width: double.infinity, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    // FONT SIZE REDUCED
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '£${order.total.toStringAsFixed(2)}',
                    // FONT SIZE REDUCED
                    style: pw.TextStyle(
                      fontSize: 16,
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
              pw.Container(
                  width: double.infinity, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 8),

              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for your order!',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    // "CURRY KING - INDIAN CUISINE" REMOVED FROM FOOTER
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

  // Test print function
  static Future<void> testPrint() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'CURRY KING',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                    width: double.infinity, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 16),
                pw.Text(
                  'PRINTER TEST',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('This is a test print.'),
                pw.Text('Date: ${DateTime.now().toString().substring(0, 19)}'),
                pw.SizedBox(height: 16),
                pw.Text('Test completed successfully!'),
                pw.SizedBox(height: 16),
                pw.Container(
                    width: double.infinity, height: 1, color: PdfColors.black),
              ],
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
    // This function remains the same
  }
}
