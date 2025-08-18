import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trans_bee/screens/booking_details_page.dart';
import 'package:trans_bee/screens/home_page.dart';

class SharedRidePage extends StatelessWidget {
  final String pickupLocation;
  final String dropLocation;
  final String date;
  final String timeSlot;
  final String vehicleType;
  final double price;
  final Map<String, int> selectedItems;

  const SharedRidePage({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.date,
    required this.timeSlot,
    required this.vehicleType,
    required this.price,
    required this.selectedItems,
  });

  // Halve the price once for shared ride
  double get sharedPrice => price / 2;

  Future<void> _addRideRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = await FirebaseFirestore.instance.collection('rides').add({
        'pickupAddress': pickupLocation,
        'dropAddress': dropLocation,
        'date': date,
        'timeSlot': timeSlot,
        'vehicleType': vehicleType,
        'price': sharedPrice, // store halved price directly
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'selectedItems': selectedItems,
        'isSharedRide': true, // mark ride as shared
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'activeRideId': docRef.id});

      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add ride, try again")),
      );
    }
  }

  Future<void> _acceptRide(
    BuildContext context,
    String rideId,
    Map<String, dynamic> rideData,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) throw Exception('Ride not found');
        final current = snap.data() as Map<String, dynamic>;
        if (current['status'] != 'waiting') {
          throw Exception('Ride is no longer available');
        }
        tx.update(docRef, {'status': 'matched'});
      });

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailsPage(
            pickupAddress: rideData['pickupAddress'] ?? rideData['pickup'] ?? '',
            dropAddress: rideData['dropAddress'] ?? rideData['drop'] ?? '',
            date: rideData['date'] ?? '',
            timeSlot: rideData['timeSlot'] ?? '',
            vehicleType: rideData['vehicleType'] ?? '',
            price: ((rideData['price'] ?? sharedPrice) as num).toDouble(),
            selectedItems: selectedItems,
            isSharedRide: true,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting ride: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Rides'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 50),
              backgroundColor: const Color.fromARGB(255, 50, 68, 183),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingDetailsPage(
                    pickupAddress: pickupLocation,
                    dropAddress: dropLocation,
                    date: date,
                    timeSlot: timeSlot,
                    vehicleType: vehicleType,
                    price: price, // full price if user cancels shared
                    selectedItems: selectedItems,
                    isSharedRide: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route: $pickupLocation → $dropLocation',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Date: $date | Time: $timeSlot'),
                  const SizedBox(height: 4),
                  Text('Vehicle: $vehicleType'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('pickupAddress', isEqualTo: pickupLocation)
                  .where('dropAddress', isEqualTo: dropLocation)
                  .where('date', isEqualTo: date)
                  .where('vehicleType', isEqualTo: vehicleType)
                  .where('status', isEqualTo: 'waiting')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rides = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rideOwner = data['userId'] as String?;
                  return rideOwner != null && rideOwner != userId;
                }).toList();

                if (rides.isEmpty) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () => _addRideRequest(context),
                      child: const Text("Add yours & wait for partner"),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final ride = rides[index];
                    final rideData = ride.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.grey[200],
                      child: ListTile(
                        title: Text("Time: ${rideData['timeSlot'] ?? ''}"),
                        subtitle: Text(
                          '${rideData['pickupAddress'] ?? rideData['pickup'] ?? ''} → '
                          '${rideData['dropAddress'] ?? rideData['drop'] ?? ''}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _acceptRide(context, ride.id, rideData),
                          child: const Text("Accept"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
