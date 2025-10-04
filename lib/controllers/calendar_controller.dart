import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

class CalendarController extends ChangeNotifier {
  final DateTime today = DateTime.now();
  late DateTime currentMonth;
  late int selectedDay;

  String selectedTab = "Events";
  String selectedFilter = "All";
  bool showFilterMenu = false;

  final List<CalendarEvent> events = [
    CalendarEvent(
      title: "Hackathon",
      date: DateTime(2025, 9, 20),
      type: "Event",
    ),
    CalendarEvent(
      title: "Math Deadline",
      date: DateTime(2025, 9, 22),
      type: "Deadline",
    ),
    CalendarEvent(
      title: "Buy Materials",
      date: DateTime(2025, 9, 23),
      type: "Reminder",
    ),
    CalendarEvent(
      title: "Team Meetup",
      date: DateTime(2025, 9, 24),
      type: "Event",
    ),
    CalendarEvent(
      title: "OS Project Due",
      date: DateTime(2025, 9, 26),
      type: "Deadline",
    ),
    CalendarEvent(
      title: "Call Advisor",
      date: DateTime(2025, 9, 26),
      type: "Reminder",
    ),
  ];

  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  CalendarController() {
    currentMonth = DateTime(today.year, today.month, 1);
    selectedDay = today.day;
  }

  int daysInMonth(DateTime m) => DateUtils.getDaysInMonth(m.year, m.month);
  int mondayBasedWeekday(DateTime d) => d.weekday % 7;
  DateTime dateFor(int day) =>
      DateTime(currentMonth.year, currentMonth.month, day);

  List<CalendarEvent> eventsForDate(DateTime date) {
    return events
        .where(
          (e) =>
              e.date.year == date.year &&
              e.date.month == date.month &&
              e.date.day == date.day,
        )
        .toList();
  }

  Color dotColor(String type) {
    switch (type) {
      case "Event":
        return Colors.greenAccent.shade400;
      case "Deadline":
        return Colors.redAccent.shade200;
      case "Reminder":
        return Colors.amber.shade400;
      default:
        return Colors.grey;
    }
  }

  void selectDay(int day) {
    selectedDay = day;
    notifyListeners();
  }

  void changeMonth(int delta) {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + delta, 1);
    notifyListeners();
  }

  void toggleTab(String tab) {
    selectedTab = tab;
    notifyListeners();
  }

  void toggleFilterMenu() {
    showFilterMenu = !showFilterMenu;
    notifyListeners();
  }

  void selectFilter(String filter) {
    selectedFilter = filter;
    showFilterMenu = false;
    notifyListeners();
  }

  void addReminder(String title, DateTime date) {
    events.add(CalendarEvent(title: title, date: date, type: "Reminder"));
    notifyListeners();
  }
}
