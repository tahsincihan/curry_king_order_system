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
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPrinter = UnifiedPrinterService.getCurrentPrinter();
    _scanForPrinters();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
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

  // NEW: Disconnect function
  Future<void> _disconnectPrinter() async {
    await UnifiedPrinterService.disconnect();
    setState(() {
      _selectedPrinter = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer disconnected'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  // NEW: Dialog to add printer by IP
  Future<void> _showAddByIpDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Printer by IP Address'),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              hintText: 'e.g., 192.168.1.100',
              labelText: 'Printer IP Address',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                if (_ipController.text.isNotEmpty) {
                  final newPrinter =
                      await UnifiedPrinterService.addNetworkPrinterByIp(
                          _ipController.text);
                  if (newPrinter != null) {
                    setState(() {
                      _printers.add(newPrinter);
                    });
                  }
                  _ipController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _testPrint() async {
    // This function remains the same
  }

  String _getPrinterTypeIcon(PrinterType type) {
    // This function remains the same
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
    // This function remains the same
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
          // NEW: Add by IP button
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            onPressed: _showAddByIpDialog,
            tooltip: 'Add Printer by IP',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForPrinters,
            tooltip: 'Rescan for printers',
          ),
        ],
      ),
      body: Column(
        children: [
          // UPDATED: Connection Status
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
                  // NEW: Disconnect Button
                  TextButton.icon(
                    onPressed: _disconnectPrinter,
                    icon: Icon(Icons.link_off, color: Colors.red[700]),
                    label: Text(
                      'Disconnect',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                Chip(
                  label: Text('${_printers.length} found'),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ),
          ),

          // Scanning indicator
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Scanning for printers...'),
                ],
              ),
            ),

          // Printer List
          Expanded(
            child: _printers.isEmpty && !_isScanning
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
                          'No printers found.\nMake sure printers are on and connected.\nTry adding a network printer by IP.',
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
                    itemCount: _printers.length,
                    itemBuilder: (context, index) {
                      final printer = _printers[index];
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Printer Setup Instructions:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                    '• WiFi/Network printers that broadcast on the network will appear automatically.'),
                Text(
                    '• If your network printer is not found, use the "Add by IP" button.'),
                Text(
                    '• For Bluetooth, enable it and pair with the printer in system settings first.'),
                Text('• Tap "Connect" to select a printer for use in the app.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
