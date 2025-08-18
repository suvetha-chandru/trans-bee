import 'package:flutter/material.dart';
import 'package:trans_bee/screens/shared_ride_page.dart';

class SelectVehiclePage extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final String date;
  final String timeSlot;
  final Map<String, int> selectedItems;  // Added this parameter
  final double distance;

  const SelectVehiclePage({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.date,
    required this.timeSlot,
    required this.selectedItems, 
     required this.distance, // Marked as required
  });

  @override
  State<SelectVehiclePage> createState() => _SelectVehiclePageState();  // Removed underscore to make public
}

class _SelectVehiclePageState extends State<SelectVehiclePage> {
  String selectedVehicle = '';
  double calculatePrice(double pricePerKm) => pricePerKm * widget.distance;

  final List<Map<String, dynamic>> vehicles = [
    {
      'name': 'Bike',
      'pricePerKm': 8.0,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcROPgMAOSuWo6AN74pk5WZmugyF2YizwfK8wA&s',
    },
    {
      'name': 'Auto',
      'pricePerKm': 15.0,
      'image':
          'https://5.imimg.com/data5/OM/AX/ZM/SELLER-4137427/3-wheeler-tempo.png',
    },
    {
      'name': 'Mini Truck',
      'pricePerKm': 25.0,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSXxN3Mu1xumo3KFYaDOIWnKz1YAf_lJXEcUQ&s',
    },
    {
      'name': 'Tempo',
      'pricePerKm': 35.0,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRp7NuREK5EHSfebNKDBKLCSZ_9wCY-D7xsuA&s',
    },
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Vehicle',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose your vehicle',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vehicles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final price = calculatePrice(vehicle['pricePerKm']);
                return VehicleCard(
                  name: vehicle['name'],
                  price: price.toStringAsFixed(2),
                  imageUrl: vehicle['image'],
                  isSelected: selectedVehicle == vehicle['name'],
                  onTap: () {
                    setState(() {
                      selectedVehicle = vehicle['name'];
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedVehicle.isNotEmpty
                ? () {
                    final selectedVehicleData = vehicles.firstWhere(
                      (v) => v['name'] == selectedVehicle,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SharedRidePage(
                          pickupLocation: widget.pickupAddress,
                          dropLocation: widget.dropAddress,
                          date: widget.date,
                          timeSlot: widget.timeSlot,
                          vehicleType: selectedVehicle,
                          price: calculatePrice(selectedVehicleData['pricePerKm']),
                          selectedItems: widget.selectedItems,  // Pass the selected items
                        ),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedVehicle.isNotEmpty
                  ? const Color.fromARGB(255, 50, 68, 183)
                  : Colors.grey[400],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color.fromARGB(255, 50, 68, 183)
                  : Color.fromRGBO(128, 128, 128, 0.1),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 50, 68, 183)
                : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              "₹$price",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}