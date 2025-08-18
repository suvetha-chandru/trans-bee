// home_page.dart
import 'package:flutter/material.dart';
import 'package:trans_bee/screens/delivery_history_page.dart';
import 'package:trans_bee/screens/home_content.dart';
import 'package:trans_bee/screens/profile_page.dart';
import 'package:trans_bee/screens/request_ride_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
        const HomeContent(),
        const RequestRidePage(),    
        const DeliveryHistoryPage(),
        const ProfilePage(), 
      ];

  void _onItemTaped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTaped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.blueGrey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.request_quote_outlined), label: "Requests"),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping),label: "Deliveries"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}