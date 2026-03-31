import 'package:intl/intl.dart';

class RiverReading {
  final String id;
  final String stationId;
  final DateTime date;
  final String timeOfDay; // Morning, Evening, Night
  final double gaugeValue;
  final String photoUrl;
  final String remarks;

  RiverReading({
    required this.id,
    required this.stationId,
    required this.date,
    required this.timeOfDay,
    required this.gaugeValue,
    required this.photoUrl,
    required this.remarks,
  });

  // Factory to create from API JSON response
  factory RiverReading.fromJson(Map<String, dynamic> json) {
    return RiverReading(
      id: json['id']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      // Handle date from API (ISO string or milliseconds)
      date: json['date'] != null
          ? (json['date'] is String
              ? DateTime.parse(json['date'])
              : DateTime.fromMillisecondsSinceEpoch(json['date']))
          : DateTime.now(),
      timeOfDay: json['timeOfDay'] ?? 'Morning',
      gaugeValue: (json['gaugeValue'] ?? 0.0).toDouble(),
      photoUrl: json['photoUrl'] ?? '',
      remarks: json['remarks'] ?? '',
    );
  }

  // Convert object to JSON (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'date': date.toIso8601String(), // Best format for .NET API
      'timeOfDay': timeOfDay,
      'gaugeValue': gaugeValue,
      'photoUrl': photoUrl,
      'remarks': remarks,
    };
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(date);

  String get formattedDateTime =>
      DateFormat('dd MMM yyyy hh:mm a').format(date);
}
