import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trans_bee/screens/home_page.dart';

class PaymentPage extends StatefulWidget {
  final double amount; // already final
  final bool isSharedRide;
  final Map<String, dynamic> bookingPayload;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.isSharedRide,
    required this.bookingPayload,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedPaymentMethod; // 'upi' or 'cod'
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'title': 'UPI Transaction', 'icon': Icons.qr_code, 'type': 'upi'},
    {'title': 'Cash on Delivery', 'icon': Icons.money, 'type': 'cod'},
  ];

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.amount; // no /2, final price already

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Payment Summary
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                const Text('Payment Summary',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Base Fare:'),
                      Text('₹${widget.amount.toStringAsFixed(2)}'),
                    ]),
                const SizedBox(height: 8),
                if (widget.isSharedRide)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shared Ride Discount:'),
                        const Text('50% applied ✅',
                            style: TextStyle(color: Colors.green)),
                      ]),
                const Divider(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green)),
                    ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Payment options
          const Text('Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._paymentMethods.map((m) => _buildPaymentOption(
                icon: m['icon'],
                title: m['title'],
                isSelected: _selectedPaymentMethod == m['type'],
                onTap: () {
                  setState(() => _selectedPaymentMethod = m['type']);
                  if (m['type'] == 'upi') {
                    _showUPIQRCode(context, totalAmount);
                  }
                },
              )),
        ]),
      ),

      // Bottom button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _selectedPaymentMethod == null
              ? null
              : () async {
                  await _processPayment(context, totalAmount);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 50, 68, 183),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _selectedPaymentMethod == 'cod' ? 'CONFIRM' : 'PAY NOW',
                  style: const TextStyle(fontSize: 16),
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue[50] : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(title),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  void _showUPIQRCode(BuildContext parentContext, double amount) {
    showDialog(
      context: parentContext,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Scan to Pay"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/qr/my_upi_qr.jpeg',
              width: 200,
              height: 250,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            const Text("UPI ID: suvethachandru07@okhdfcbank"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _processPayment(parentContext, amount);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            child: const Text("I Paid"),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, double finalAmount) async {
    if (_isProcessing || _selectedPaymentMethod == null) return;
    setState(() => _isProcessing = true);

    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final isUPI = _selectedPaymentMethod == 'upi';

    if (user != null) {
      // 1️⃣ Save booking to user's collection
      final bookingDoc = {
        ...widget.bookingPayload,
        'totalAmount': finalAmount,
        'paymentMethod': _selectedPaymentMethod,
        'paid': isUPI,
        'booked': true,
        'paymentStatusLabel': isUPI ? 'Paid & Booked' : 'Booked and COD',
        'paymentStatus': isUPI ? 'paid_booked' : 'booked_cod',
        'createdAt': now.toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .add({
        ...bookingDoc,
        'userId': user.uid,
      });

      // 2️⃣ Update rides collection
      if (widget.bookingPayload.containsKey('rideId')) {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.bookingPayload['rideId'])
            .update({'status': 'completed', 'finalPrice': finalAmount});
      }

      // 3️⃣ Remove activeRideId from user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'activeRideId': FieldValue.delete()});
    }

    setState(() => _isProcessing = false);

    Navigator.pop(context, isUPI ? 'UPI' : 'COD');
  }
}
