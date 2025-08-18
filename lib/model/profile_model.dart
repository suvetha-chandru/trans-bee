import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String name;
  final String mobile;
  final String address;
  final String? imageUrl;
  final String? localImagePath;

  const Profile({
    required this.name,
    required this.mobile,
    required this.address,
    this.imageUrl,
    this.localImagePath,
  });

  Profile copyWith({
    String? name,
    String? mobile,
    String? address,
    String? imageUrl,
    String? localImagePath,
  }) {
    return Profile(
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobile': mobile,
      'address': address,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: (map['name'] as String?) ?? '',
      mobile: (map['mobile'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
