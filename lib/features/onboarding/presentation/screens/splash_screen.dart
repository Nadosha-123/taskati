import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/animation_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_lottie.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Object? _loadError;
  bool _isNavigating = false;

  Future<void> _openNextScreen() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final profile = await ref.read(profileProvider.future);
      if (!mounted) return;
      context.goNamed(
        profile?.isComplete == true
            ? RouteNames.home
            : RouteNames.completeProfile,
      );
    } catch (error) {
      _isNavigating = false;
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLottie(
                    assetPath: AnimationPaths.intro,
                    repeat: false,
                    onCompleted: _openNextScreen,
                  ),
                  Text(
                    'Taskati',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It’s time to get organized',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Could not load your profile: $_loadError',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(profileProvider);
                        setState(() => _loadError = null);
                        _openNextScreen();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
