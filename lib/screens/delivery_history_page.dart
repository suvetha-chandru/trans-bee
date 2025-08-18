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

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.03;
    final spacing = screenHeight * 0.01;
    final iconSize = screenHeight * 0.022;
    final fontSize = screenHeight * 0.018;

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
            padding: EdgeInsets.all(padding),
            itemCount: docs.length,
            separatorBuilder: (_, __) => SizedBox(height: spacing),
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
                  padding: EdgeInsets.symmetric(horizontal: padding * 2),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    await doc.reference.delete();
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
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route Information
                        Row(
                          children: [
                            Icon(Icons.local_shipping, size: iconSize),
                            SizedBox(width: padding),
                            Expanded(
                              child: Text(
                                '$pickup → $drop',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: fontSize),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        // Date & Status
                        Row(
                          children: [
                            Icon(Icons.event, size: iconSize, color: Colors.grey),
                            SizedBox(width: padding * 0.5),
                            Expanded(
                              child: Text(
                                '$date • $time',
                                style: TextStyle(color: Colors.grey, fontSize: fontSize),
                                softWrap: true,
                              ),
                            ),
                            if (statusLabel.isNotEmpty)
                              Text(
                                statusLabel.toUpperCase(),
                                style: TextStyle(
                                  color: statusLabel.contains('Paid')
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: spacing),
                        // Vehicle & Amount
                        Row(
                          children: [
                            Icon(Icons.directions_car_filled,
                                size: iconSize, color: Colors.grey),
                            SizedBox(width: padding * 0.5),
                            Expanded(
                              child: Text(
                                vehicle,
                                style: TextStyle(fontSize: fontSize),
                                softWrap: true,
                              ),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: fontSize),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
