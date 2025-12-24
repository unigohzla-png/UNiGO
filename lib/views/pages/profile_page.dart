import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controllers/profile_controller.dart';
import '../../models/student_model.dart';
import '../widgets/glass_appbar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_card_custom.dart';
import 'personal_info_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController controller = ProfileController();
  late Future<Student?> _future;

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _future = controller.getStudent();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true, // IMPORTANT: so we get bytes
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final Uint8List? bytes = file.bytes;
      final String ext = (file.extension ?? '').toLowerCase();

      if (bytes == null) {
        throw Exception(
          'Could not read image bytes. Please try another image.',
        );
      }
      if (ext.isEmpty) {
        throw Exception('Unknown image type. Please pick JPG or PNG.');
      }

      setState(() => _uploading = true);

      await controller.uploadProfilePhoto(bytes: bytes, extension: ext);

      if (!mounted) return;
      setState(() {
        _future = controller.getStudent(); // refresh UI
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _showPhotoMenu() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove current picture'),
                onTap: () async {
                  Navigator.pop(context);

                  setState(() => _uploading = true);
                  try {
                    await controller.removeProfilePhoto();
                    if (!mounted) return;
                    setState(() {
                      _future = controller.getStudent();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile photo removed.')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Remove failed: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _uploading = false);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const GlassAppBar(title: "Profile"),
      body: FutureBuilder<Student?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No student data found."));
          }

          final student = snapshot.data!;
          final hasPhoto = student.profileImage.trim().isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _uploading ? null : _showPhotoMenu,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: hasPhoto
                            ? NetworkImage(student.profileImage)
                            : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: IconButton(
                          icon: _uploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt),
                          onPressed: _uploading ? null : _showPhotoMenu,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'University of Jordan - Amman',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  student.major,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 28),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Basic Information",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  title: "Payment Number",
                  value: student.paynum,
                  isRectangular: true,
                ),
                GlassCard(
                  title: "University Email",
                  value: student.email,
                  isRectangular: true,
                ),
                GlassCard(
                  title: "Advisor",
                  value: student.advisor,
                  isRectangular: true,
                ),

                GlassCardCustom(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location & DOB',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student.location,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '|',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              student.dob,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInfoPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.6),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 6,
                      shadowColor: Colors.black26,
                    ),
                    child: const Text("View Personal Info"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
