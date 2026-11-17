import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/profile.dart';
import '../../domain/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw StateError('ProfileRepository has not been initialized.'),
);

final profileProvider = AsyncNotifierProvider<ProfileController, Profile?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() => ref.read(profileRepositoryProvider).load();

  Future<void> save(Profile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = AsyncData(profile);
  }
}
