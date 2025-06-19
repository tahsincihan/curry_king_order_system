import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/order_provider.dart';
import 'services/sales_provider.dart';

// Import screens
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize sales provider
  final salesProvider = SalesProvider();
  await salesProvider.initialize();
  
  runApp(MyApp(salesProvider: salesProvider));
}

class MyApp extends StatelessWidget {
  final SalesProvider salesProvider;
  
  const MyApp({Key? key, required this.salesProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProvider.value(value: salesProvider),
      ],
      child: MaterialApp(
        title: 'Curry King Order Pad',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}