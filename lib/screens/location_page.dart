import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:trans_bee/screens/select_vehicle_page.dart';

class ServiceBookingPage extends StatefulWidget {
  final Map<String, int> selectedItems;

  const ServiceBookingPage({super.key, required this.selectedItems});

  @override
  State<ServiceBookingPage> createState() => _ServiceBookingPageState();
}

class _ServiceBookingPageState extends State<ServiceBookingPage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  LatLng _mapCenter = const LatLng(11.1271, 78.6569); // Tamil Nadu center
  double _currentZoom = 6.5;
  double _zoomLevel = 7.0;
  bool _showMap = false;
  bool _isPickupSelection = true;
  bool _isLoading = false;

  final MapController _mapController = MapController(); // added map controller

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await _getMobileLocation();
    } catch (e) {
      debugPrint("Location initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not determine location. Please select manually"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getMobileLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services are disabled");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions permanently denied");
    }

    final position = await Geolocator.getCurrentPosition();
    await _updateLocation(position.latitude, position.longitude);
  }

  Future<void> _updateLocation(double lat, double lng) async {
    if (!mounted) return;
    if (_isWithinTamilNadu(lat, lng)) {
      final address = await _getAddressFromLatLng(lat, lng);
      if (mounted) {
        setState(() {
          _mapCenter = LatLng(lat, lng);
          _zoomLevel = 12.0;
        });
      }
    }
  }

  bool _isWithinTamilNadu(double lat, double lng) {
    return lat > 8.0 && lat < 13.5 && lng > 76.0 && lng < 80.5;
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty) {
        final place = places.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea
        ].where((p) => p != null && p.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return "Near ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _showLocationMap(bool isPickup) {
    if (!mounted) return;
    setState(() {
      _showMap = true;
      _isPickupSelection = isPickup;
    });
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (!_isWithinTamilNadu(point.latitude, point.longitude)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a location within Tamil Nadu")),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final address = await _getAddressFromLatLng(point.latitude, point.longitude);
      if (mounted) {
        setState(() {
          if (_isPickupSelection) {
            _pickupLocation = point;
            _pickupController.text = address;
          } else {
            _dropLocation = point;
            _dropController.text = address;
          }
          _showMap = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateDistance() {
    if (_pickupLocation == null || _dropLocation == null) return 0.0;
    return Geolocator.distanceBetween(
          _pickupLocation!.latitude,
          _pickupLocation!.longitude,
          _dropLocation!.latitude,
          _dropLocation!.longitude,
        ) /
        1000; // km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Service (Tamil Nadu Only)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showMap
              ? _buildMapView()
              : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    final distance = _calculateDistance();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: _pickupController,
            decoration: InputDecoration(
              labelText: 'Pickup Location',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _showLocationMap(true),
              ),
            ),
            readOnly: true,
            onTap: () => _showLocationMap(true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dropController,
            decoration: InputDecoration(
              labelText: 'Drop Location',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _showLocationMap(false),
              ),
            ),
            readOnly: true,
            onTap: () => _showLocationMap(false),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: 'Date',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_pickupLocation == null ||
                  _dropLocation == null ||
                  _dateController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfirmationPage(
                      pickupAddress: _pickupController.text,
                      dropAddress: _dropController.text,
                      date: _dateController.text,
                      selectedItems: widget.selectedItems,
                      distance: distance,
                    ),
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
  return Stack(
    children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _mapCenter,  // use initialCenter
          initialZoom: _currentZoom,  // use initialZoom
          minZoom: 5.0,
          maxZoom: 16.0,
          onTap: (tapPosition, point) => _handleMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: [
              if (_pickupLocation != null)
                Marker(
                  point: _pickupLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              if (_dropLocation != null)
                Marker(
                  point: _dropLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
      // Back button
      Positioned(
        top: 16,
        left: 16,
        child: FloatingActionButton(
          onPressed: () => setState(() => _showMap = false),
          mini: true,
          child: const Icon(Icons.arrow_back),
        ),
      ),
      // Zoom buttons
      Positioned(
        top: 16,
        right: 16,
        child: Column(
          children: [
            FloatingActionButton(
              heroTag: 'zoom_in',
              onPressed: () {
                setState(() {
                  _currentZoom = (_currentZoom + 1).clamp(5.0, 16.0);
                  _mapController.move(_mapCenter, _currentZoom);
                });
              },
              mini: true,
              child: const Icon(Icons.zoom_in),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'zoom_out',
              onPressed: () {
                setState(() {
                  _currentZoom = (_currentZoom - 1).clamp(5.0, 16.0);
                  _mapController.move(_mapCenter, _currentZoom);
                });
              },
              mini: true,
              child: const Icon(Icons.zoom_out),
            ),
          ],
        ),
      ),
    ],
  );
}

}

// ConfirmationPage class stays the same (your original code is fine)


class ConfirmationPage extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final String date;
  final Map<String, int> selectedItems;
  final double distance;

  const ConfirmationPage({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.date,
    required this.selectedItems,
    required this.distance,
  });

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final TextEditingController _pickupHouseNoController = TextEditingController();
  final TextEditingController _pickupMobileController = TextEditingController();
  final TextEditingController _dropHouseNoController = TextEditingController();
  final TextEditingController _dropMobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedTimeSlot;
  final List<String> _timeSlots = [
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 1:00 PM',
    '1:00 PM - 2:00 PM',
    '2:00 PM - 3:00 PM',
    '3:00 PM - 4:00 PM',
    '4:00 PM - 5:00 PM',
    '5:00 PM - 6:00 PM',
    '6:00 PM - 7:00 PM',
    '7:00 PM - 8:00 PM',
    '8:00 PM - 9:00 PM',
    '9:00 PM - 10:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking Details"), centerTitle: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Pickup Address"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pickupHouseNoController,
                decoration: const InputDecoration(
                  labelText: 'House No/Street*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter house number/street' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.pickupAddress,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pickupMobileController,
                decoration: const InputDecoration(
                  labelText: 'Sender Mobile Number*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter mobile number';
                  if (value.length < 10) return 'Enter valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Drop Address"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _dropHouseNoController,
                decoration: const InputDecoration(
                  labelText: 'House No/Street*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter house number/street' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.dropAddress,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dropMobileController,
                decoration: const InputDecoration(
                  labelText: 'Receiver Mobile Number*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter mobile number';
                  if (value.length < 10) return 'Enter valid 10-digit number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Booking Date"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [const Icon(Icons.calendar_today), const SizedBox(width: 12), Text(widget.date, style: const TextStyle(fontSize: 16))],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Select Time of Pickup"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeSlot,
                  hint: const Text("Select time slot"),
                  isExpanded: true,
                  items: _timeSlots.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (newValue) => setState(() => _selectedTimeSlot = newValue),
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectVehiclePage(
                            pickupAddress: widget.pickupAddress,
                            dropAddress: widget.dropAddress,
                            date: widget.date,
                            timeSlot: _selectedTimeSlot ?? 'Not selected',
                            selectedItems: widget.selectedItems,
                            distance: widget.distance,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    backgroundColor: const Color.fromARGB(255, 50, 68, 183),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("CONFIRM BOOKING"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      );
}
