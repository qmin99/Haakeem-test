/// Represents a contact in the system
class Contact {
  final String name;
  final String role;
  final bool isOnline;
  bool isSelected;

  Contact({
    required this.name,
    required this.role,
    required this.isOnline,
    this.isSelected = false,
  });

  /// Creates a copy of this contact with updated properties
  Contact copyWith({
    String? name,
    String? role,
    bool? isOnline,
    bool? isSelected,
  }) {
    return Contact(
      name: name ?? this.name,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Converts the contact to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'isOnline': isOnline,
      'isSelected': isSelected,
    };
  }

  /// Creates a Contact from a map
  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isSelected: map['isSelected'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.name == name && other.role == role;
  }

  @override
  int get hashCode => name.hashCode ^ role.hashCode;
}

