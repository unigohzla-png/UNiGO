class Reservation {
  final String registerDate;
  final String registerTime;
  final String freeDate;
  final String freeTime;

  Reservation({
    required this.registerDate,
    required this.registerTime,
    required this.freeDate,
    required this.freeTime,
  });

  Map<String, dynamic> toJson() => {
    "registerDate": registerDate,
    "registerTime": registerTime,
    "freeDate": freeDate,
    "freeTime": freeTime,
  };

  static Reservation fromJson(Map<String, dynamic> json) => Reservation(
    registerDate: json["registerDate"] ?? "",
    registerTime: json["registerTime"] ?? "",
    freeDate: json["freeDate"] ?? "",
    freeTime: json["freeTime"] ?? "",
  );
}
