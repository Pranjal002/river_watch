class RiverStation {
  final String id;
  final String name;
  final String location;

  RiverStation({
    required this.id,
    required this.name,
    required this.location,
  });

  factory RiverStation.fromJson(Map<String, dynamic> json) {
    return RiverStation(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Station',
      location: json['location'] ?? '',
    );
  }
}
