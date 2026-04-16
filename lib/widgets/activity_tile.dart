import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../core/app_theme.dart';

class ActivityTile extends StatelessWidget {
  final String title;
  final String location;
  final String description;
  final bool hasJoined;
  final bool isLoading;
  final VoidCallback onJoin;

  const ActivityTile({
    super.key,
    required this.title,
    required this.location,
    required this.description,
    required this.hasJoined,
    required this.onJoin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AidColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🔥 Title row (FIXED)
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AidColors.volunteerAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (hasJoined)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AidColors.volunteerAccent.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AidColors.volunteerAccent.withValues(alpha:0.4),
                    ),
                  ),
                  child: Text(
                    'Joined ✓',
                    style: TextStyle(
                      color: AidColors.volunteerAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const Gap(6),

          // 📍 Location
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white54),
              const Gap(4),
              Text(
                location,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
            ],
          ),

          const Gap(10),

          // 📝 Description
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const Gap(14),

          // 🔥 Join button
          if (!hasJoined)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AidColors.volunteerAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Join Activity',
                        style: TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}