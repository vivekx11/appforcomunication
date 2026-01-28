/// Meeting model for room management
class Meeting {
  final String roomId;
  final String hostName;
  final List<String> participants;
  final DateTime createdAt;

  Meeting({
    required this.roomId,
    required this.hostName,
    required this.participants,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'hostName': hostName,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      roomId: json['roomId'],
      hostName: json['hostName'],
      participants: List<String>.from(json['participants']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
