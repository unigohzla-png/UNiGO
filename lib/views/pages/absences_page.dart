import 'dart:ui';
import 'package:flutter/material.dart';
import '../../controllers/absences_controller.dart';
import 'package:provider/provider.dart';

class AbsencesPage extends StatelessWidget {
  const AbsencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AbsencesController(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Absences",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Consumer<AbsencesController>(
          builder: (context, controller, _) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.absences.length,
              itemBuilder: (context, index) {
                final course = controller.absences[index];
                final max = controller.getMaxSections(course["days"]);
                final value = course["value"];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course["title"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),

                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 12,
                                thumbShape: SliderComponentShape.noThumb,
                                overlayShape: SliderComponentShape.noOverlay,
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: List.generate(
                                          max,
                                          (i) => Color.lerp(
                                            Colors.orange.shade200,
                                            Colors.red.shade900,
                                            i / (max - 1),
                                          )!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Slider(
                                    value: value,
                                    max: (max - 1).toDouble(),
                                    divisions: max - 1,
                                    onChanged: null,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),
                            Text(
                              "Absences: ${value.toInt()} / $max",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
