import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trans_bee/screens/home_page.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // ✅ Razorpay import

class PaymentPage extends StatefulWidget {
  final double amount; 
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

  late Razorpay _razorpay; // ✅ Razorpay instance

  final List<Map<String, dynamic>> _paymentMethods = [
    {'title': 'Online Transaction', 'icon': Icons.qr_code, 'type': 'upi'},
    {'title': 'Cash on Delivery', 'icon': Icons.money, 'type': 'cod'},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ✅ Razorpay callbacks
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await _processPayment(context, widget.amount);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment failed. Try again.")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
    );
  }

  void _openRazorpayCheckout(double amount) {
    var options = {
      'key': 'rzp_test_R8KdLweu7ASxsU', // 🔑 replace with your Razorpay key
      'amount': (amount * 100).toInt(), // Razorpay uses paise
      'name': 'TransBee',
      'description': 'Ride Payment',
      'method': {
        'upi': true, // ✅ Enable UPI
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.amount;

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
                    _openRazorpayCheckout(totalAmount); 
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
                  if (_selectedPaymentMethod == 'cod') {
                    await _processPayment(context, totalAmount);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  }
                  // For UPI, Razorpay triggers success callback
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

  // ✅ Save to Firestore
  Future<void> _processPayment(BuildContext context, double finalAmount) async {
    if (_isProcessing || _selectedPaymentMethod == null) return;
    setState(() => _isProcessing = true);

    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final isUPI = _selectedPaymentMethod == 'upi';

    if (user != null) {
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

      if (widget.bookingPayload.containsKey('rideId')) {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.bookingPayload['rideId'])
            .update({'status': 'completed', 'finalPrice': finalAmount});
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'activeRideId': FieldValue.delete()});
    }

    setState(() => _isProcessing = false);
  }
}
