import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:trans_bee/screens/select_vehicle_page.dart';
import 'dart:convert';

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
  LatLng _mapCenter = const LatLng(11.1271, 78.6569);
  double _zoomLevel = 7.0;
  bool _showMap = false;
  bool _isPickupSelection = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await _getWebLocation();
      } else {
        await _getMobileLocation();
      }
    } catch (e) {
      debugPrint("Location initialization error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not determine location. Please select manually",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getWebLocation() async {
    try {
      final position = await _getBrowserPosition();
      if (position != null) {
        await _updateLocation(position['latitude']!, position['longitude']!);
      }
    } catch (e) {
      throw Exception("Please enable location services in your browser");
    }
  }

  Future<Map<String, double>?> _getBrowserPosition() async {
    try {
      if (kIsWeb) {
        final position = await _getBrowserGeolocation();
        return {
          'latitude': position['latitude'] ?? 0.0, // Default to 0.0 if null
          'longitude': position['longitude'] ?? 0.0,
        };
      }
      return null;
    } catch (e) {
      debugPrint("Browser geolocation error: $e");
      return null;
    }
  }

  Future<Map<String, double>> _getBrowserGeolocation() async {
    throw UnimplementedError("Web geolocation not implemented");
  }

  Future<void> _getMobileLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

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
          _pickupLocation = _mapCenter;
          _pickupController.text = address;
        });
      }
    }
  }

  bool _isWithinTamilNadu(double lat, double lng) {
    return lat > 8.0 && lat < 13.5 && lng > 76.0 && lng < 80.5;
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      if (kIsWeb) {
        final response = await http.get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
          ),
        );
        final data = json.decode(response.body);
        return _formatWebAddress(data['address']);
      } else {
        final places = await placemarkFromCoordinates(lat, lng);
        if (places.isNotEmpty) {
          final place = places.first;
          return "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}"
              .replaceAll(RegExp(r'^,\s*|\s*,\s*$'), '');
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
    return "Near ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }

  String _formatWebAddress(Map<String, dynamic> address) {
    return [
      address['road'],
      address['village'],
      address['town'],
      address['city'],
      address['state'],
    ].where((part) => part != null).join(', ');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
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
          const SnackBar(
            content: Text("Please select a location within Tamil Nadu"),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final address = await _getAddressFromLatLng(
        point.latitude,
        point.longitude,
      );
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
    } catch (e) {
      debugPrint("Address fetch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not get address for this location"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        1000; // Convert meters to kilometers
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
          options: MapOptions(
            initialCenter: _mapCenter, // Changed from 'center'
            initialZoom: _zoomLevel,
            maxZoom: 16.0,
            minZoom: 7.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onTap: (tapPosition, point) => _handleMapTap(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                if (_pickupLocation != null)
                  Marker(
                    point: _pickupLocation!,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                if (_dropLocation != null)
                  Marker(
                    point: _dropLocation!,
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
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton(
            onPressed: () {
              if (mounted) {
                setState(() => _showMap = false);
              }
            },
            mini: true,
            child: const Icon(Icons.arrow_back),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withAlpha(200)),
            child: Text(
              _isPickupSelection
                  ? "Tap on map to select pickup location (TN only)"
                  : "Tap on map to select drop location (TN only)",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

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
  final TextEditingController _pickupHouseNoController =
      TextEditingController();
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
      appBar: AppBar(
        title: const Text("Confirm Booking Details"),
        centerTitle: true,
      ),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter house number/street';
                  }
                  return null;
                },
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length < 10) {
                    return 'Enter valid 10-digit number';
                  }
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter house number/street';
                  }
                  return null;
                },
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length < 10) {
                    return 'Enter valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Booking Date"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(widget.date, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Select Time of Pickup"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeSlot,
                  hint: const Text("Select time slot"),
                  isExpanded: true,
                  items: _timeSlots.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _selectedTimeSlot = newValue),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
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
                              distance: widget.distance),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 50),
                    backgroundColor: const Color.fromARGB(255, 50, 68, 183),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
