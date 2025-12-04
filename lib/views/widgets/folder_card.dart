import 'dart:ui';
import 'package:flutter/material.dart';

class FolderCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool isListView;
  final bool isWithdrawn;

  const FolderCard({
    super.key,
    required this.title,
    required this.assetPath,
    this.isListView = false,
    this.isWithdrawn = false,
  });

  @override
  Widget build(BuildContext context) {
    return isListView ? _buildListViewCard() : _buildGridViewCard();
  }

  Widget _buildGridViewCard() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/course',
              arguments: {'title': title, 'asset': assetPath},
            );
          },
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 160,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: Colors.white.withOpacity(0.25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Image.asset(assetPath, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  if (isWithdrawn)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.lock, size: 14, color: Colors.grey),
                            SizedBox(width: 6),
                            Text(
                              'Withdrawn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListViewCard() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/course',
              arguments: {'title': title, 'asset': assetPath},
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (isWithdrawn)
                  const Icon(Icons.lock, color: Colors.grey)
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }
}

