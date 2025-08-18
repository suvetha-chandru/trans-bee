import 'package:flutter/material.dart';
import 'package:trans_bee/screens/location_page.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final Map<String, List<String>> categories = {
    'Living Room': [
      'Chairs',
      'Tables',
      'TV/Monitor',
      'Cabinet/Storage',
      'Sofa',
      'Home Utility',
    ],
    'Bedroom': [
      'Tables',
      'Chairs',
      'Mattress',
      'Bed frame',
      'AC/Cooler/Fan',
      'Cabinet/Storage',
      'Almirah/Wardrobe',
    ],
    'Kitchen': ['Fridge', 'Electrical/Gas Appliances', 'Cabinet/Storage'],
    'Others': [
      'Self Carton Box',
      'Gunny bag',
      'Washing Machine',
      'Bathroom Utility',
      'Home Utility',
      'Vehicle',
      'Equipment/Instruments',
      'Plant',
      'Suitcase/Trolley',
    ],
  };

  final Map<String, int> itemCounts = {};

  @override
  void initState() {
    super.initState();
    // Initialize all item counts to 0
    for (var items in categories.values) {
      for (var item in items) {
        itemCounts[item] = 0;
      }
    }
  }

  void increment(String item) {
    setState(() {
      itemCounts[item] = itemCounts[item]! + 1;
    });
  }

  void decrement(String item) {
    setState(() {
      if (itemCounts[item]! > 0) {
        itemCounts[item] = itemCounts[item]! - 1;
      }
    });
  }

  Map<String, int> getSelectedItems() {
    return Map.from(itemCounts)..removeWhere((key, value) => value <= 0);
  }

  Widget buildItemRow(String item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: () => decrement(item),
              ),
              Text('${itemCounts[item]}', style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => increment(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCategory(String category, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map(buildItemRow),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Items', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.entries
                .map((e) => buildCategory(e.key, e.value))
                .toList(),
          ),
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              final selectedItems = getSelectedItems();
              if (selectedItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select at least one item to continue"),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ServiceBookingPage(selectedItems: selectedItems),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 50),
              backgroundColor: const Color.fromARGB(255, 50, 68, 183),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Continue"),
          ),
        ),
      ),
    );
  }
}