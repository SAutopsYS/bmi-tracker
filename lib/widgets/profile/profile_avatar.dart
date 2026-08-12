import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/utils/local_file_image.dart';
import 'package:bmi_tracker/models/enums.dart';

/// Circular avatar with image or initials fallback by name/gender.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.gender,
    this.imagePath,
    this.radius = 24,
    this.onTap,
  });

  final String name;
  final Gender? gender;
  final String? imagePath;
  final double radius;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Color _fallbackColor(ColorScheme scheme) {
    switch (gender) {
      case Gender.male:
        return scheme.primary;
      case Gender.female:
        return scheme.secondary;
      case Gender.other:
        return scheme.tertiary;
      case Gender.preferNotToSay:
      case null:
        return scheme.primary.withValues(alpha: 0.85);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = imagePath;
    final image =
        (path != null && path.isNotEmpty) ? localFileImage(path) : null;
    final hasImage = image != null;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: _fallbackColor(scheme).withValues(alpha: 0.18),
      foregroundColor: _fallbackColor(scheme),
      backgroundImage: image,
      child: hasImage
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.72,
              ),
            ),
    );

    return Semantics(
      label: 'Profile avatar for $name',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}
