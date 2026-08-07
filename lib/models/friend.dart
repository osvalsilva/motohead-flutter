class Friend {
  final int id;
  final String name;
  final String? email;
  final String? avatar;
  final String? city;
  final String? state;
  final String? personalStatus;
  final String? phone;
  final String? friendsSince;

  Friend({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.city,
    this.state,
    this.personalStatus,
    this.phone,
    this.friendsSince,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      avatar: json['avatar'],
      city: json['city'],
      state: json['state'],
      personalStatus: json['personal_status'],
      phone: json['phone'],
      friendsSince: json['friends_since'],
    );
  }
}