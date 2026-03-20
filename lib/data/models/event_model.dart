/// A local community event in Eskişehir.
class EventModel {
  final String id;
  final String title;
  final String locationName;
  final DateTime dateTime;
  final int attendeeCount;
  final String description;
  final bool isJoined;

  const EventModel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.dateTime,
    required this.attendeeCount,
    required this.description,
    this.isJoined = false,
  });

  factory EventModel.empty() {
    return EventModel(
      id: '',
      title: '',
      locationName: '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(0),
      attendeeCount: 0,
      description: '',
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      dateTime: json['dateTime'] is String
          ? DateTime.tryParse(json['dateTime'] as String) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      attendeeCount: json['attendeeCount'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      isJoined: json['isJoined'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'locationName': locationName,
      'dateTime': dateTime.toIso8601String(),
      'attendeeCount': attendeeCount,
      'description': description,
      'isJoined': isJoined,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? locationName,
    DateTime? dateTime,
    int? attendeeCount,
    String? description,
    bool? isJoined,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      locationName: locationName ?? this.locationName,
      dateTime: dateTime ?? this.dateTime,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      description: description ?? this.description,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  bool get isEmpty => id.isEmpty;

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, location: $locationName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
