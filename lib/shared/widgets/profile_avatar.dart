import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    this.imagePath,
    this.radius = 24,
    super.key,
  });

  final String name;
  final String? imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return Semantics(
      label: name.isEmpty ? 'User avatar' : '$name profile photo',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ClipOval(
          child: path == null || path.isEmpty
              ? _defaultImage()
              : Image.file(
                  File(path),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _defaultImage(),
                ),
        ),
      ),
    );
  }

  Widget _defaultImage() => Image.asset(
    'assets/images/default_avatar.png',
    width: radius * 2,
    height: radius * 2,
    fit: BoxFit.cover,
  );
}
