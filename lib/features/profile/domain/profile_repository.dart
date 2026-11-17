import 'profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> load();
  Future<void> save(Profile profile);
}
