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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final sectionSpacing = screenHeight * 0.02;
    final cardPadding = screenWidth * 0.04;
    final fontSizeLabel = screenHeight * 0.022;
    final fontSizeHeader = screenHeight * 0.025;
    final buttonHeight = screenHeight * 0.065;
    final buttonFontSize = screenHeight * 0.022;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(cardPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Route Information
                    _buildSectionHeader('Route Information', fontSizeHeader),
                    _buildDetailCard(
                      padding: cardPadding,
                      children: [
                        _buildDetailRow('Pickup:', pickupAddress, fontSize: fontSizeLabel),
                        _buildDetailRow('Drop:', dropAddress, fontSize: fontSizeLabel),
                        _buildDetailRow('Date:', date, fontSize: fontSizeLabel),
                        _buildDetailRow('Time Slot:', timeSlot, fontSize: fontSizeLabel),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),

                    // Items Information
                    _buildSectionHeader('Items to Transport', fontSizeHeader),
                    if (itemsList.isEmpty)
                      Text(
                        'No items selected',
                        style: TextStyle(color: Colors.grey, fontSize: fontSizeLabel),
                      )
                    else
                      _buildDetailCard(
                        padding: cardPadding,
                        children: itemsList
                            .map((item) => _buildDetailRow('${item.key}:', '${item.value}',
                                fontSize: fontSizeLabel))
                            .toList()
                            .cast<Widget>(),
                      ),
                    SizedBox(height: sectionSpacing),

                    // Vehicle Information
                    _buildSectionHeader('Vehicle Information', fontSizeHeader),
                    _buildDetailCard(
                      padding: cardPadding,
                      children: [
                        _buildDetailRow('Vehicle Type:', vehicleType, fontSize: fontSizeLabel),
                        _buildDetailRow('Ride Type:',
                            isSharedRide ? 'Shared Ride' : 'Private Ride',
                            fontSize: fontSizeLabel),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),

                    // Payment Summary
                    _buildSectionHeader('Payment Summary', fontSizeHeader),
                    _buildDetailCard(
                      padding: cardPadding,
                      children: [
                        _buildDetailRow('Base Price:', '₹${price.toStringAsFixed(2)}',
                            fontSize: fontSizeLabel),
                        if (isSharedRide)
                          _buildDetailRow('Shared Ride Discount:', '50% applied ✅',
                              fontSize: fontSizeLabel),
                        Divider(height: sectionSpacing),
                        _buildDetailRow(
                          'Total Amount:',
                          '₹${price.toStringAsFixed(2)}',
                          isBold: true,
                          valueColor: Colors.green,
                          fontSize: fontSizeLabel,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: buttonHeight * 0.3),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(color: Colors.black, fontSize: buttonFontSize),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        SizedBox(width: cardPadding),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentPage(
                                    amount: price,
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
                              padding: EdgeInsets.symmetric(vertical: buttonHeight * 0.3),
                            ),
                            child: Text(
                              'Confirm Booking',
                              style: TextStyle(color: Colors.white, fontSize: buttonFontSize),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailCard({required List<Widget> children, required double padding}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    required double fontSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: fontSize * 0.25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
