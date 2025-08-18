import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trans_bee/screens/booking_details_page.dart';

class RequestRidePage extends StatefulWidget {
  const RequestRidePage({super.key});

  @override
  State<RequestRidePage> createState() => _RequestRidePageState();
}

class _RequestRidePageState extends State<RequestRidePage> {
  String? activeRideId;

  @override
  void initState() {
    super.initState();
    _fetchActiveRide();
  }

  Future<void> _fetchActiveRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final rideId = userDoc.data()?['activeRideId'] as String?;
    setState(() {
      activeRideId = rideId;
    });
  }

  Future<void> _cancelRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || activeRideId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(activeRideId)
          .update({'status': 'cancelled'});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'activeRideId': FieldValue.delete()});

      setState(() {
        activeRideId = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel ride')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activeRideId == null || activeRideId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Ride Request")),
        body: const Center(child: Text("No active ride request yet")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Ride Request")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rides")
            .doc(activeRideId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Ride not found"));
          }

          final rideData = snapshot.data!.data() as Map<String, dynamic>;
          final statusRaw = (rideData['status'] ?? "requested").toString();

          // Remove ride if completed or cancelled
          if (statusRaw == "completed" || statusRaw == "cancelled") {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'activeRideId': FieldValue.delete()});
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => activeRideId = null);
            });
            return const Center(child: Text("No active ride request yet"));
          }

          final pickupLocation = rideData['pickupAddress'] ?? "Unknown";
          final dropLocation = rideData['dropAddress'] ?? "Unknown";
          final date = rideData['date'] ?? "Unknown";
          final timeSlot = rideData['timeSlot'] ?? "Unknown";
          final vehicleType = rideData['vehicleType'] ?? "Unknown";
          final double price = (rideData['price'] ?? 0).toDouble();
          final selectedItems =
              Map<String, int>.from(rideData['selectedItems'] ?? {});

          final isMatchedOrAccepted =
              statusRaw == "matched" || statusRaw == "accepted";

          // Correct display price logic:
          final double displayPrice = 
              (statusRaw == "accepted" || statusRaw == "matched") ? price  : price*2;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "$pickupLocation → $dropLocation",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isMatchedOrAccepted
                                ? Colors.green[100]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isMatchedOrAccepted
                                ? "Accepted"
                                : _capitalize(statusRaw),
                            style: TextStyle(
                              color: isMatchedOrAccepted
                                  ? Colors.green[800]
                                  : Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("$date • $timeSlot",
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text("Vehicle: $vehicleType",
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "₹${displayPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
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
                                  price: displayPrice,
                                  selectedItems: selectedItems,
                                ),
                              ),
                            );
                          },
                          child: const Text("View Details"),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelRide,
                          child: const Text("Cancel"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';
}
