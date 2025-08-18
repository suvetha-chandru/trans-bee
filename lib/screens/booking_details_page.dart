import 'package:flutter/material.dart';
import 'package:trans_bee/screens/payment_page.dart';

class BookingDetailsPage extends StatelessWidget {
  final String pickupAddress;
  final String dropAddress;
  final String date;
  final String timeSlot;
  final String vehicleType;
  final double price; // already halved if shared
  final Map<String, int> selectedItems;
  final bool isSharedRide;

  const BookingDetailsPage({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.date,
    required this.timeSlot,
    required this.vehicleType,
    required this.price,
    required this.selectedItems,
    this.isSharedRide = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, int>> itemsList =
        selectedItems.entries.where((entry) => entry.value > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Information
            _buildSectionHeader('Route Information'),
            _buildDetailCard(
              children: [
                _buildDetailRow('Pickup:', pickupAddress),
                _buildDetailRow('Drop:', dropAddress),
                _buildDetailRow('Date:', date),
                _buildDetailRow('Time Slot:', timeSlot),
              ],
            ),
            const SizedBox(height: 20),

            // Items Information
            _buildSectionHeader('Items to Transport'),
            if (itemsList.isEmpty)
              const Text('No items selected', style: TextStyle(color: Colors.grey))
            else
              _buildDetailCard(
                children: itemsList
                    .map((item) => _buildDetailRow('${item.key}:', '${item.value}'))
                    .toList(),
              ),
            const SizedBox(height: 20),

            // Vehicle Information
            _buildSectionHeader('Vehicle Information'),
            _buildDetailCard(
              children: [
                _buildDetailRow('Vehicle Type:', vehicleType),
                _buildDetailRow('Ride Type:', isSharedRide ? 'Shared Ride' : 'Private Ride'),
              ],
            ),
            const SizedBox(height: 20),

            // Payment Summary
            _buildSectionHeader('Payment Summary'),
            _buildDetailCard(
              children: [
                _buildDetailRow('Base Price:', '₹${price.toStringAsFixed(2)}'),
                if (isSharedRide)
                  _buildDetailRow(
                    'Shared Ride Discount:',
                    '50% applied ✅', // just a label
                  ),
                const Divider(height: 20),
                _buildDetailRow(
                  'Total Amount:',
                  '₹${price.toStringAsFixed(2)}', // final price
                  isBold: true,
                  valueColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Back', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            amount: price, // pass final price
                            isSharedRide: isSharedRide,
                            bookingPayload: {
                              "pickupAddress": pickupAddress,
                              "dropAddress": dropAddress,
                              "date": date,
                              "timeSlot": timeSlot,
                              "vehicleType": vehicleType,
                              "price": price,
                              "selectedItems": selectedItems,
                              "isSharedRide": isSharedRide,
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 50, 68, 183),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirm Booking', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailCard({required List<Widget> children}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
        ],
      ),
    );
  }
}
