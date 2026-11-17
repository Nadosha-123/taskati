import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile.dart';
import '../domain/profile_repository.dart' as domain;

class PreferencesProfileRepository implements domain.ProfileRepository {
  const PreferencesProfileRepository(this._preferences);

  static const _nameKey = 'profile_name';
  static const _imagePathKey = 'profile_image_path';
  static const _isCompleteKey = 'profile_is_complete';

  final SharedPreferences _preferences;

  @override
  Future<Profile?> load() async {
    final name = _preferences.getString(_nameKey);
    if (name == null) return null;

    return Profile(
      name: name,
      imagePath: _preferences.getString(_imagePathKey),
      isComplete: _preferences.getBool(_isCompleteKey) ?? false,
    );
  }

  @override
  Future<void> save(Profile profile) async {
    await _preferences.setString(_nameKey, profile.name);
    await _preferences.setBool(_isCompleteKey, profile.isComplete);
    if (profile.imagePath == null) {
      await _preferences.remove(_imagePathKey);
    } else {
      await _preferences.setString(_imagePathKey, profile.imagePath!);
    }
  }
}
