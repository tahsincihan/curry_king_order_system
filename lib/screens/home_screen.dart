import 'package:flutter/material.dart';
import 'takeaway_order_screen.dart';
import 'dine_in_screen.dart';
import 'printer_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: Text('Curry King Order Pad'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrinterSettingsScreen(),
                ),
              );
            },
            tooltip: 'Printer Settings',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.orange[700],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'CURRY KING',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'INDIAN CUISINE',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[600],
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 50),
            
            // Order Type Selection
            Text(
              'Select Order Type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Takeaway Button
            Container(
              width: 300,
              height: 80,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TakeawayOrderScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.takeout_dining, size: 30),
                    SizedBox(width: 15),
                    Text(
                      'TAKEAWAY',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Dine In Button
            Container(
              width: 300,
              height: 80,
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DineInOrderScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 30),
                    SizedBox(width: 15),
                    Text(
                      'DINE IN',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}