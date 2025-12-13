import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/calendar_controller.dart';
import '../../main.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarController(),
      child: const _CalendarScaffold(),
    );
  }
}

class _CalendarScaffold extends StatelessWidget {
  const _CalendarScaffold();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<CalendarController>(context);

    final daysCount = controller.daysInMonth(controller.currentMonth);
    final startOffset = controller.mondayBasedWeekday(controller.currentMonth);

    // 🔹 Use TODAY for the left side, regardless of what is selected
    final DateTime today = controller.today;
    final String leftDayName = CalendarController.weekdays[today.weekday % 7];
    final String leftMonthName = CalendarController.months[today.month - 1];

    // (we still keep selectedDay for highlighting and filtering)
    final DateTime selectedDate = controller.dateFor(controller.selectedDay);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Calendar",
          style: TextStyle(
            fontFamily: "IBMPlexSans",
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ======= Glass Calendar Card =======
            _glass(
              child: SizedBox(
                height: 300,
                child: Row(
                  children: [
                    // LEFT: Day / Date / Month
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              leftDayName,
                              style: const TextStyle(
                                fontFamily: "IBMPlexSans",
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${today.day}", // 👈 always today's date
                              style: const TextStyle(
                                fontFamily: "IBMPlexSans",
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              leftMonthName,
                              style: const TextStyle(
                                fontFamily: "IBMPlexSans",
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 44),
                      color: Colors.black.withOpacity(0.08),
                    ),

                    // RIGHT: Calendar
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 18, 16, 20),
                        child: Column(
                          children: [
                            // Weekday initials
                            Padding(
                              padding: const EdgeInsets.only(left: 5.0),
                              child: GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 7,
                                physics: const NeverScrollableScrollPhysics(),
                                children: const [
                                  _WD('S'),
                                  _WD('M'),
                                  _WD('T'),
                                  _WD('W'),
                                  _WD('T'),
                                  _WD('F'),
                                  _WD('S'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Calendar grid
                            SizedBox(
                              height: 175,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(left: 6),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: 13,
                                      crossAxisSpacing: 10,
                                    ),
                                itemCount: startOffset + daysCount,
                                itemBuilder: (context, i) {
                                  if (i < startOffset) {
                                    return const SizedBox.shrink();
                                  }
                                  final day = i - startOffset + 1;
                                  final date = DateTime(
                                    controller.currentMonth.year,
                                    controller.currentMonth.month,
                                    day,
                                  );
                                  final isSelected =
                                      day == controller.selectedDay;
                                  final dayEvents = controller.eventsForDate(
                                    date,
                                  );

                                  return GestureDetector(
                                    onTap: () => controller.selectDay(day),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (isSelected)
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black87,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Text(
                                          "$day",
                                          style: TextStyle(
                                            fontFamily: "IBMPlexSans",
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: dayEvents.take(3).map((
                                              e,
                                            ) {
                                              return Container(
                                                width: 4,
                                                height: 4,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 0.5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: controller.dotColor(
                                                    e.type,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Month nav
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _glassIconButton(
                                  icon: Icons.chevron_left,
                                  onTap: () => controller.changeMonth(-1),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${CalendarController.months[controller.currentMonth.month - 1]} ${controller.currentMonth.year}",
                                  style: const TextStyle(
                                    fontFamily: "IBMPlexSans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _glassIconButton(
                                  icon: Icons.chevron_right,
                                  onTap: () => controller.changeMonth(1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ======= Events / Reminders card =======
            _glass(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _bigTab("Events", controller),
                        const SizedBox(width: 10),
                        _bigTab("Reminders", controller),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // FILTER + LIST
                    if (controller.selectedTab == "Events") ...[
                      const SizedBox(height: 10),

                      // Always-visible pill filters (Events only)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterListItem("All", controller),
                            _filterListItem(
                              "Event",
                              controller,
                              swatch: controller.dotColor("Event"),
                            ),
                            _filterListItem(
                              "Deadline",
                              controller,
                              swatch: controller.dotColor("Deadline"),
                            ),
                            _filterListItem(
                              "Reminder",
                              controller,
                              swatch: controller.dotColor("Reminder"),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      ..._buildEventCards(controller),
                    ] else ...[
                      const SizedBox(height: 12),
                      ..._buildReminderCards(controller),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
//                   LIST BUILDERS
// ===========================================================

List<Widget> _buildEventCards(CalendarController controller) {
  final today = controller.today;
  final tappedDate = controller.dateFor(controller.selectedDay);

  // Normalize today to midnight
  final DateTime todayStart = DateTime(today.year, today.month, today.day);
  // End of this month
  final DateTime endOfMonth = DateTime(today.year, today.month + 1, 0);

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  final bool tappedIsToday = isSameDay(tappedDate, today);

  final filtered = controller.events.where((e) {
    final DateTime d = DateTime(e.date.year, e.date.month, e.date.day);

    // 1) Type filter
    if (controller.selectedFilter != "All" &&
        e.type != controller.selectedFilter) {
      return false;
    }

    // 2) When filter == "All"
    if (controller.selectedFilter == "All") {
      if (!tappedIsToday) {
        // ✅ User selected a specific day → show ONLY that day's events
        return isSameDay(d, tappedDate);
      } else {
        // ✅ Default "All" behavior for today → show from today to end of month
        return !d.isBefore(todayStart) && !d.isAfter(endOfMonth);
      }
    }

    // 3) When filter is specific (Event / Deadline / Reminder)
    if (!tappedIsToday) {
      // ✅ User selected a specific day → show ONLY that day's events (of that type)
      return isSameDay(d, tappedDate);
    }

    // 4) Specific filter + today selected → keep old "today to 2 weeks" behavior
    final twoWeeksFromNow = today.add(const Duration(days: 14));
    return d.isAfter(todayStart.subtract(const Duration(days: 1))) &&
        d.isBefore(twoWeeksFromNow);
  }).toList();

  if (filtered.isEmpty) {
    return const [
      Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          "No events to show.",
          style: TextStyle(
            fontFamily: "IBMPlexSans",
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ),
    ];
  }

  return filtered.map((e) {
    final color = controller.dotColor(e.type);
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          // Jump highlight to this event's date when you tap the card
          controller.selectDate(e.date);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: _glass(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          style: const TextStyle(
                            fontFamily: "IBMPlexSans",
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${CalendarController.months[e.date.month - 1]} "
                          "${e.date.day}, ${e.date.year} • ${e.type}",
                          style: TextStyle(
                            fontFamily: "IBMPlexSans",
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }).toList();
}

List<Widget> _buildReminderCards(CalendarController controller) {
  final reminders = controller.events
      .where((e) => e.type == "Reminder")
      .toList();

  final widgets = <Widget>[];

  if (reminders.isEmpty) {
    // Show a hint if there are no reminders
    widgets.add(
      const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Text(
          "No reminders yet.",
          style: TextStyle(
            fontFamily: "IBMPlexSans",
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ),
    );
  } else {
    // Show existing reminders
    widgets.addAll(
      reminders.map((e) {
        return Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              // Jump calendar highlight to this reminder's date
              controller.selectDate(e.date);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _glass(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "• ${e.title} — "
                          "${CalendarController.months[e.date.month - 1]} ${e.date.day}",
                          style: const TextStyle(
                            fontFamily: "IBMPlexSans",
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          controller.deleteReminder(e);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ✅ Always show "Add Reminder" button
  widgets.add(const SizedBox(height: 10));
  widgets.add(
    Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () => _showAddReminderDialog(controller),
        icon: const Icon(Icons.add),
        label: const Text("Add Reminder"),
      ),
    ),
  );
  return widgets;
}

// ===========================================================
//                 ADD REMINDER DIALOG
// ===========================================================

void _showAddReminderDialog(CalendarController controller) {
  String reminderTitle = "";
  DateTime? reminderDate;

  showDialog(
    context: navigatorKey.currentContext!,
    builder: (context) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.85),
            title: const Text(
              "Add Reminder",
              style: TextStyle(fontFamily: "IBMPlexSans"),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Reminder Title",
                  ),
                  onChanged: (v) => reminderTitle = v,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.today,
                      firstDate: DateTime(
                        controller.today.year,
                        controller.today.month - 1,
                      ),
                      lastDate: DateTime(
                        controller.today.year,
                        controller.today.month + 12,
                      ),
                    );
                    if (picked != null) reminderDate = picked;
                  },
                  child: Text(
                    reminderDate == null
                        ? "Pick Date"
                        : "Picked: ${CalendarController.months[reminderDate!.month - 1]} ${reminderDate!.day}",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (reminderTitle.isNotEmpty && reminderDate != null) {
                    await controller.addReminder(reminderTitle, reminderDate!);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ===========================================================
//               SMALL UI HELPERS / WIDGETS
// ===========================================================

Widget _bigTab(String tab, CalendarController controller) {
  final isActive = controller.selectedTab == tab;
  return GestureDetector(
    onTap: () => controller.toggleTab(tab),
    child: _glass(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          tab,
          style: TextStyle(
            fontFamily: "IBMPlexSans",
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.black : Colors.black54,
          ),
        ),
      ),
    ),
  );
}

Widget _filterListItem(
  String label,
  CalendarController controller, {
  Color? swatch,
}) {
  final isActive = controller.selectedFilter == label;
  return GestureDetector(
    onTap: () => controller.selectFilter(label),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.45)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999), // full pill
        border: Border.all(
          color: isActive
              ? Colors.black.withOpacity(0.6)
              : Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
            ),
            const SizedBox(width: 1),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: "IBMPlexSans",
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.black : Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _glass({required Widget child}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.28),
              Colors.white.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.45), width: 1),
        ),
        child: child,
      ),
    ),
  );
}

// if any old code still calls glass(), forward to _glass
Widget glass({required Widget child}) => _glass(child: child);

Widget _glassIconButton({
  required IconData icon,
  required VoidCallback onTap,
  double size = 28,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Material(
        color: Colors.white.withOpacity(0.2),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.64, color: Colors.black87),
          ),
        ),
      ),
    ),
  );
}

class _WD extends StatelessWidget {
  final String t;
  const _WD(this.t);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        t,
        style: const TextStyle(
          fontFamily: "IBMPlexSans",
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black54,
        ),
      ),
    );
  }
}
