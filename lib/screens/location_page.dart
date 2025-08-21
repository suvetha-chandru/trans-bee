import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:trans_bee/screens/select_vehicle_page.dart';

// District data for Tamil Nadu
const List<Map<String, dynamic>> tamilNaduDistricts = [
  {"name": "Ariyalur", "lat": 11.1375, "lng": 79.0758},
  {"name": "Chennai", "lat": 13.0827, "lng": 80.2707},
  {"name": "Coimbatore", "lat": 11.0168, "lng": 76.9558},
  {"name": "Cuddalore", "lat": 11.7447, "lng": 79.7680},
  {"name": "Dharmapuri", "lat": 12.1211, "lng": 78.1582},
  {"name": "Dindigul", "lat": 10.3670, "lng": 77.9803},
  {"name": "Erode", "lat": 11.3428, "lng": 77.7274},
  {"name": "Kallakurichi", "lat": 11.7404, "lng": 78.9590},
  {"name": "Kancheepuram", "lat": 12.8342, "lng": 79.7036},
  {"name": "Karur", "lat": 10.9574, "lng": 78.0809},
  {"name": "Krishnagiri", "lat": 12.5186, "lng": 78.2137},
  {"name": "Madurai", "lat": 9.9252, "lng": 78.1198},
  {"name": "Mayiladuthurai", "lat": 11.1035, "lng": 79.6550},
  {"name": "Nagapattinam", "lat": 10.7667, "lng": 79.8417},
  {"name": "Namakkal", "lat": 11.2216, "lng": 78.1659},
  {"name": "Nilgiris", "lat": 11.4600, "lng": 76.6400},
  {"name": "Perambalur", "lat": 11.2229, "lng": 78.8823},
  {"name": "Pudukkottai", "lat": 10.3833, "lng": 78.8167},
  {"name": "Ramanathapuram", "lat": 9.3716, "lng": 78.8307},
  {"name": "Ranipet", "lat": 12.9344, "lng": 79.3314},
  {"name": "Salem", "lat": 11.6643, "lng": 78.1460},
  {"name": "Sivaganga", "lat": 9.8432, "lng": 78.4809},
  {"name": "Tenkasi", "lat": 8.9733, "lng": 77.3020},
  {"name": "Thanjavur", "lat": 10.7865, "lng": 79.1378},
  {"name": "Theni", "lat": 10.0104, "lng": 77.4768},
  {"name": "Thoothukudi", "lat": 8.7642, "lng": 78.1348},
  {"name": "Tiruchirappalli", "lat": 10.7905, "lng": 78.7047},
  {"name": "Tirunelveli", "lat": 8.7139, "lng": 77.7567},
  {"name": "Tirupathur", "lat": 12.4976, "lng": 78.5599},
  {"name": "Tiruppur", "lat": 11.1085, "lng": 77.3411},
  {"name": "Tiruvallur", "lat": 13.1449, "lng": 79.9086},
  {"name": "Tiruvannamalai", "lat": 12.2266, "lng": 79.0746},
  {"name": "Tiruvarur", "lat": 10.7726, "lng": 79.6368},
  {"name": "Vellore", "lat": 12.9165, "lng": 79.1325},
  {"name": "Viluppuram", "lat": 11.9426, "lng": 79.4973},
  {"name": "Virudhunagar", "lat": 9.5853, "lng": 77.9579},
  {"name": "Chengalpattu", "lat": 12.6828, "lng": 79.9768},
  {"name": "Tirupattur", "lat": 12.4976, "lng": 78.5599},
];

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

  final MapController _mapController = MapController();

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
    
    // Find nearest district
    var nearestDistrict = _findNearestDistrict(lat, lng);
    if (nearestDistrict != null) {
      if (mounted) {
        setState(() {
          _mapCenter = LatLng(nearestDistrict['lat'], nearestDistrict['lng']);
          _zoomLevel = 7.0;
        });
      }
    }
  }

  Map<String, dynamic>? _findNearestDistrict(double lat, double lng) {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestDistrict;
    
    for (var district in tamilNaduDistricts) {
      double distance = Geolocator.distanceBetween(
        lat, lng, district['lat'], district['lng']);
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestDistrict = district;
      }
    }
    
    return nearestDistrict;
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

  void _handleDistrictSelection(Map<String, dynamic> district) {
    if (!mounted) return;
    
    setState(() {
      if (_isPickupSelection) {
        _pickupLocation = LatLng(district['lat'], district['lng']);
        _pickupController.text = district['name'];
      } else {
        _dropLocation = LatLng(district['lat'], district['lng']);
        _dropController.text = district['name'];
      }
      _showMap = false;
    });
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
              labelText: 'Pickup District',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _showLocationMap(true),
              ),
            ),
            readOnly: false,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dropController,
            decoration: InputDecoration(
              labelText: 'Drop District',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _showLocationMap(false),
              ),
            ),
            readOnly: false,
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
              if (_pickupController.text.isEmpty ||
                  _dropController.text.isEmpty ||
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
            initialCenter: _mapCenter,
            initialZoom: _currentZoom,
            minZoom: 6.0, // Prevent zooming in too close
            maxZoom: 8.0, // Prevent zooming out too far
            interactionOptions: const InteractionOptions(
    flags: InteractiveFlag.drag | 
           InteractiveFlag.flingAnimation | 
           InteractiveFlag.pinchZoom | 
           InteractiveFlag.doubleTapZoom,
  ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
              markers: [
                for (var district in tamilNaduDistricts)
                  Marker(
                    point: LatLng(district['lat'], district['lng']),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _handleDistrictSelection(district),
                      child: Icon(
                        Icons.location_pin,
                        color: (_pickupLocation != null && 
                                _pickupLocation!.latitude == district['lat'] && 
                                _pickupLocation!.longitude == district['lng'])
                            ? Colors.green
                            : (_dropLocation != null && 
                                _dropLocation!.latitude == district['lat'] && 
                                _dropLocation!.longitude == district['lng'])
                                ? Colors.red
                                : Colors.blue,
                        size: 40,
                      ),
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
            onPressed: () => setState(() => _showMap = false),
            mini: true,
            child: const Icon(Icons.arrow_back),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                onPressed: () {
                  setState(() {
                    _currentZoom = (_currentZoom + 0.5).clamp(6.0, 8.0);
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
                    _currentZoom = (_currentZoom - 0.5).clamp(6.0, 8.0);
                    _mapController.move(_mapCenter, _currentZoom);
                  });
                },
                mini: true,
                child: const Icon(Icons.zoom_out),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isPickupSelection 
                    ? "Select Pickup District" 
                    : "Select Drop District",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ConfirmationPage remains the same as in your original code
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
  final TextEditingController _pickupAddressController = TextEditingController();
  final TextEditingController _dropAddressController = TextEditingController();

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
  void initState() {
    super.initState();
    _pickupAddressController.text = widget.pickupAddress;
    _dropAddressController.text = widget.dropAddress;
  }

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
                controller: _pickupAddressController,
                decoration: const InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                readOnly: false,
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
                controller: _dropAddressController,
                decoration: const InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                readOnly: false,
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
                            pickupAddress: _pickupAddressController.text,
                            dropAddress: _dropAddressController.text,
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