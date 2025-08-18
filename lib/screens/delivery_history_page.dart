import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeliveryHistoryPage extends StatelessWidget {
  const DeliveryHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final bookingsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No deliveries yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final pickup = data['pickupAddress'] ?? '';
              final drop = data['dropAddress'] ?? '';
              final date = data['date'] ?? '';
              final time = data['timeSlot'] ?? '';
              final vehicle = data['vehicleType'] ?? '';
              final amount =
                  (data['totalAmount'] ?? data['basePrice'] ?? 0.0) as num;
              final statusLabel = data['paymentStatusLabel'] ?? '';
              final rideId = data['rideId'] as String?;

              return Dismissible(
                key: ValueKey(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  // Use mounted context via SchedulerBinding
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    // Delete the booking
                    await doc.reference.delete();

                    // Delete the ride if rideId exists
                    if (rideId != null) {
                      await FirebaseFirestore.instance
                          .collection('rides')
                          .doc(rideId)
                          .delete();
                    }

                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Booking & ride deleted')),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                },
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: route + status
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$pickup → $drop',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('$date • $time',
                                style: const TextStyle(color: Colors.grey)),
                            const Spacer(),
                            if (statusLabel.isNotEmpty)
                              Text(
                                statusLabel.toUpperCase(),
                                style: TextStyle(
                                    color: statusLabel.contains('Paid')
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.directions_car_filled,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(vehicle),
                            const Spacer(),
                            Text('₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}
