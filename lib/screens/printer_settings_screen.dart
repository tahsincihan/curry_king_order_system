import 'package:flutter/material.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  void _initPrinter() async {
    bluetoothPrint.scanResults.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });

    bluetoothPrint.state.listen((state) {
      setState(() {
        _isConnected = state == BluetoothPrint.CONNECTED;
      });
    });

    // Check if already connected
    bool? isConnected = await bluetoothPrint.isConnected;
    setState(() {
      _isConnected = isConnected ?? false;
    });
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    bluetoothPrint.startScan(timeout: Duration(seconds: 10));

    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        _isScanning = false;
      });
      bluetoothPrint.stopScan();
    });
  }

  void _stopScan() {
    bluetoothPrint.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    if (_isConnected) {
      await _disconnect();
    }

    try {
      await bluetoothPrint.connect(device);
      setState(() {
        _connectedDevice = device;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnect() async {
    try {
      await bluetoothPrint.disconnect();
      setState(() {
        _connectedDevice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disconnected from printer'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testPrint() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please connect to a printer first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      List<LineText> testLines = [
        LineText(
          type: LineText.TYPE_TEXT,
          content: '================================',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'CURRY KING',
          weight: 2,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'INDIAN CUISINE',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: '================================',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 1,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'PRINTER TEST',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 2,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'This is a test print.',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Date: ${DateTime.now().toString().substring(0, 19)}',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 1,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Printer: ${_connectedDevice?.name ?? 'Unknown'}',
          weight: 0,
          align: LineText.ALIGN_LEFT,
          linefeed: 2,
        ),
        LineText(
          type: LineText.TYPE_TEXT,
          content: 'Test completed successfully!',
          weight: 1,
          align: LineText.ALIGN_CENTER,
          linefeed: 3,
        ),
      ];

      await bluetoothPrint.printReceipt(testLines);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Printer Settings'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Connection Status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: _isConnected ? Colors.green[50] : Colors.red[50],
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      if (_isConnected && _connectedDevice != null)
                        Text(
                          'Device: ${_connectedDevice!.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isConnected) ...[
                  ElevatedButton(
                    onPressed: _testPrint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Test Print'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _disconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Disconnect'),
                  ),
                ],
              ],
            ),
          ),

          // Scan Controls
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Available Bluetooth Printers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScan : _startScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_isScanning ? Icons.stop : Icons.search),
                  label: Text(_isScanning ? 'Stop Scan' : 'Scan'),
                ),
              ],
            ),
          ),

          // Scanning indicator
          if (_isScanning)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
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

          // Device List
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Scanning for printers...'
                              : 'No printers found.\nTap "Scan" to search for printers.',
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
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = _devices[index];
                      bool isConnectedDevice = _connectedDevice?.address == device.address;
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            Icons.print,
                            color: isConnectedDevice ? Colors.green : Colors.grey,
                          ),
                          title: Text(
                            device.name ?? 'Unknown Device',
                            style: TextStyle(
                              fontWeight: isConnectedDevice ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(device.address ?? ''),
                          trailing: isConnectedDevice
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : ElevatedButton(
                                  onPressed: () => _connectToDevice(device),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Connect'),
                                ),
                        ),
                      );
                    },
                  ),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Make sure your Bluetooth printer is turned on',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '2. Put the printer in pairing/discoverable mode',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '3. Tap "Scan" to search for available printers',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '4. Tap "Connect" next to your printer',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '5. Use "Test Print" to verify the connection',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bluetoothPrint.stopScan();
    super.dispose();
  }
}