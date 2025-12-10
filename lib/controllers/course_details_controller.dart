// lib/controllers/course_details_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/grade_models.dart';

class MaterialItem {
  final String id;
  final String title;
  final String type;
  final String meta;

  MaterialItem({
    required this.id,
    required this.title,
    required this.type,
    required this.meta,
  });

  factory MaterialItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MaterialItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      meta: (data['meta'] ?? '') as String,
    );
  }
}

class AnnouncementItem {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool pinned;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.pinned,
  });

  factory AnnouncementItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'] as Timestamp?;
    return AnnouncementItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      createdAt: ts?.toDate(),
      pinned: (data['pinned'] ?? false) as bool,
    );
  }
}

class SectionInfo {
  final int id;
  final List<String> days;
  final String? location;
  final String? startTime;
  final String? endTime;
  final String? doctorName;

  SectionInfo({
    required this.id,
    required this.days,
    this.location,
    this.startTime,
    this.endTime,
    this.doctorName,
  });
}

class CourseDetailsController extends ChangeNotifier {
  final String courseTitle;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool loadingCourse = true;
  bool loadingMaterials = false;
  bool loadingGrades = false;
  bool loadingAnnouncements = false;

  String? courseCode;
  String? courseNameFromDb;

  SectionInfo? sectionInfo;
  List<SectionInfo> sections = [];

  List<MaterialItem> materials = [];
  List<GradeItem> grades = [];
  List<AnnouncementItem> announcements = [];

  double totalScore = 0;
  double totalMax = 0;

  int _safeInt(dynamic v, {int def = 1}) {
    if (v == null) return def;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return def;
  }

  CourseDetailsController({required this.courseTitle}) {
    _init();
  }

  String get title => courseNameFromDb ?? courseTitle;

  Future<void> _init() async {
    try {
      debugPrint('CD: _init for title = $courseTitle');

      // find course by name
      final courseSnap = await _db
          .collection('courses')
          .where('name', isEqualTo: courseTitle)
          .limit(1)
          .get();

      debugPrint('CD: courseSnap size = ${courseSnap.docs.length}');

      if (courseSnap.docs.isEmpty) {
        loadingCourse = false;
        notifyListeners();
        return;
      }

      final doc = courseSnap.docs.first;
      final data = doc.data();

      debugPrint('CD: course doc id = ${doc.id}');
      debugPrint('CD: data keys = ${data.keys.toList()}');

      courseCode = (data['code'] ?? doc.id).toString();
      courseNameFromDb = (data['name'] ?? courseTitle) as String;

      // --- parse ALL sections from the course doc (safe) ---
      sections = [];
      sectionInfo = null;

      final dynamic rawSectionsDynamic = data['sections'];
      debugPrint(
        'CD: rawSectionsDynamic runtimeType = '
        '${rawSectionsDynamic.runtimeType}',
      );

      if (rawSectionsDynamic is List) {
        for (final item in rawSectionsDynamic) {
          try {
            Map<String, dynamic> m;

            if (item is Map<String, dynamic>) {
              m = item;
            } else if (item is Map) {
              m = <String, dynamic>{};
              item.forEach((k, v) => m[k.toString()] = v);
            } else {
              debugPrint('CD: section item is NOT a map: $item');
              continue;
            }

            final sec = SectionInfo(
              id: _safeInt(m['id']),
              days: ((m['days'] as List<dynamic>?) ?? [])
                  .map((e) => e.toString())
                  .toList(),
              location: m['location'] as String?,
              startTime: m['startTime'] as String?,
              endTime: m['endTime'] as String?,
              doctorName: m['doctorName'] as String?,
            );

            sections.add(sec);
          } catch (e, st) {
            debugPrint('CD: error parsing one section: $e');
            debugPrint(st.toString());
          }
        }
      } else {
        debugPrint('CD: sections field is not a List: $rawSectionsDynamic');
      }

      debugPrint('CD: parsed sections length = ${sections.length}');
      if (sections.isNotEmpty) {
        sectionInfo = sections.first;
      }

      debugPrint('CD: parsed sections length = ${sections.length}');

      if (sections.isNotEmpty) {
        sectionInfo = sections.first;
      }

      await Future.wait([
        _loadMaterials(),
        _loadAnnouncements(),
        _loadGrades(),
      ]);
    } catch (e, st) {
      debugPrint('CourseDetailsController _init ERROR: $e');
      debugPrint(st.toString());
    } finally {
      loadingCourse = false;
      notifyListeners();
    }
  }

  Future<void> _loadMaterials() async {
    if (courseCode == null) return;

    loadingMaterials = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('courses')
          .doc(courseCode!)
          .collection('materials')
          .get();

      materials = snap.docs
          .map(
            (d) => MaterialItem.fromDoc(
              d as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('CourseDetailsController _loadMaterials ERROR: $e');
      debugPrint(st.toString());
    } finally {
      loadingMaterials = false;
      notifyListeners();
    }
  }

  Future<void> _loadAnnouncements() async {
    if (courseCode == null) return;

    loadingAnnouncements = true;
    notifyListeners();

    try {
      // simple order by date; no compound index required
      final snap = await _db
          .collection('courses')
          .doc(courseCode!)
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .get();

      announcements = snap.docs
          .map(
            (d) => AnnouncementItem.fromDoc(
              d as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint('CourseDetailsController _loadAnnouncements ERROR: $e');
      debugPrint(st.toString());
    } finally {
      loadingAnnouncements = false;
      notifyListeners();
    }
  }

  Future<void> _loadGrades() async {
    if (courseCode == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    loadingGrades = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('courses')
          .doc(courseCode!)
          .collection('grades')
          .where('confirmed', isEqualTo: true) // 🔹 only confirmed
          .get();

      grades = snap.docs
          .map(
            (d) =>
                GradeItem.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>),
          )
          .where((g) => g.confirmed) // extra safety
          .toList();

      // 🔹 sort locally by order so no Firestore index is needed
      grades.sort((a, b) => a.order.compareTo(b.order));

      totalScore = grades.fold(0.0, (sum, g) => sum + g.score);
      totalMax = grades.fold(0.0, (sum, g) => sum + g.maxScore);
    } catch (e, st) {
      debugPrint('CourseDetailsController _loadGrades ERROR: $e');
      debugPrint(st.toString());
      grades = [];
      totalScore = 0;
      totalMax = 0;
    } finally {
      loadingGrades = false;
      notifyListeners();
    }
  }
}
