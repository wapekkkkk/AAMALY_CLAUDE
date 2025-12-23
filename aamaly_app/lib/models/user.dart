// ============================================
// FILE: lib/models/user.dart (UPDATED WITH fromMap)
// ============================================

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastActive;
  final String qrCode;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.isOnline = false,
    this.lastActive,
    required this.qrCode,
  });

  // ✅ ADD THIS METHOD - For Firestore
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'],
      isOnline: map['isOnline'] ?? false,
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as dynamic).toDate()
          : null,
      qrCode: map['qrCode'] ?? '',
    );
  }

  // ✅ ADD THIS METHOD - For Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastActive': lastActive,
      'qrCode': qrCode,
    };
  }

  // Get initials for avatar (e.g., "Ahmad Student" -> "AS")
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  // Get status text
  String get statusText {
    if (isOnline) return 'Online';
    if (lastActive == null) return 'Offline';

    final difference = DateTime.now().difference(lastActive!);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Keep your existing fromJson
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      isOnline: json['isOnline'] ?? false,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      qrCode: json['qrCode'] ?? '',
    );
  }

  // Keep your existing toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastActive': lastActive?.toIso8601String(),
      'qrCode': qrCode,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    bool? isOnline,
    DateTime? lastActive,
    String? qrCode,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}
