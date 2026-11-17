class Profile {
  const Profile({
    required this.name,
    required this.imagePath,
    required this.isComplete,
  });

  final String name;
  final String? imagePath;
  final bool isComplete;
}
