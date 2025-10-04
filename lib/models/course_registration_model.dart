class CourseRegistration {
  final String code;
  final String name;
  final int credits;
  bool isRegistered;

  CourseRegistration({
    required this.code,
    required this.name,
    required this.credits,
    this.isRegistered = false,
  });
}
