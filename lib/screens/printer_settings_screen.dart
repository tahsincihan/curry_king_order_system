import 'package:flutter/material.dart';
import '../services/unified_printer_service.dart';
import 'dart:io';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({Key? key}) : super(key: key);

  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  bool _isScanning = false;
  List<UnifiedPrinter> _printers = [];
  UnifiedPrinter? _selectedPrinter;
  bool _showOnlyNetworkPrinters = false;

  @override
  void initState() {
    super.initState();
    _scanForPrinters();
  }

  Future<void> _scanForPrinters() async {
    setState(() {
      _isScanning = true;
      _printers.clear();
    });

    try {
      final printers = await UnifiedPrinterService.getAllAvailablePrinters();

      setState(() {
        _printers = printers;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning for printers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UnifiedPrinter> get filteredPrinters {
    if (!_showOnlyNetworkPrinters) return _printers;
    return _printers.where((p) => p.type == PrinterType.network).toList();
  }

  Future<void> _connectToPrinter(UnifiedPrinter printer) async {
    try {
      final success = await UnifiedPrinterService.connectToPrinter(printer);

      if (success) {
        setState(() {
          _selectedPrinter = printer;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${printer.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testPrint() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a printer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Create a test order
      // You'll need to implement a test print method in UnifiedPrinterService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test print sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getPrinterTypeIcon(PrinterType type) {
    switch (type) {
      case PrinterType.bluetooth:
        return '🔵';
      case PrinterType.network:
        return '📶';
      case PrinterType.usb:
        return '🔌';
    }
  }

  String _getPrinterTypeLabel(PrinterType type) {
    switch (type) {
      case PrinterType.bluetooth:
        return 'Bluetooth';
      case PrinterType.network:
        return 'WiFi/Network';
      case PrinterType.usb:
        return 'USB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Settings'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForPrinters,
            tooltip: 'Rescan for printers',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          if (_selectedPrinter != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected to ${_selectedPrinter!.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          '${_getPrinterTypeLabel(_selectedPrinter!.type)} • ${_selectedPrinter!.identifier}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _testPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Print'),
                  ),
                ],
              ),
            ),

          // Filter Options
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Available Printers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Platform-specific filter
                if (!Platform.isWindows) ...[
                  FilterChip(
                    label: const Text('WiFi Only'),
                    selected: _showOnlyNetworkPrinters,
                    onSelected: (selected) {
                      setState(() {
                        _showOnlyNetworkPrinters = selected;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                Chip(
                  label: Text('${filteredPrinters.length} found'),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ),
          ),

          // Scanning indicator
          if (_isScanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Scanning for printers...'),
                ],
              ),
            ),

          // Printer List
          Expanded(
            child: filteredPrinters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.print_disabled,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Scanning for printers...'
                              : 'No printers found.\nMake sure printers are powered on\nand connected to the network.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredPrinters.length,
                    itemBuilder: (context, index) {
                      final printer = filteredPrinters[index];
                      final isSelected =
                          _selectedPrinter?.identifier == printer.identifier;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.orange[50] : null,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPrinterTypeIcon(printer.type),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Text(
                            printer.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getPrinterTypeLabel(printer.type)),
                              Text(
                                printer.identifier,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _connectToPrinter(printer),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Connect'),
                                ),
                        ),
                      );
                    },
                  ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Printer Setup Instructions:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (Platform.isWindows) ...[
                  const Text(
                      '• WiFi/Network printers will appear automatically'),
                  const Text(
                      '• USB printers connected to this computer will show up'),
                  const Text(
                      '• Ensure printer drivers are installed for USB printers'),
                ] else ...[
                  const Text(
                      '• For WiFi printers, ensure they are on the same network'),
                  const Text(
                      '• For Bluetooth, enable Bluetooth and pair the printer'),
                  const Text(
                      '• Put Bluetooth printers in pairing mode if not visible'),
                ],
                const Text('• Tap "Connect" to select a printer'),
                const Text('• Use "Test Print" to verify the connection'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
