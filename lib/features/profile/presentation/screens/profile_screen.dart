import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_theme_toggle.dart';
import '../../../../core/widgets/figma_background.dart';
import '../../../../core/widgets/figma_back_button.dart';
import '../../../../core/widgets/figma_button.dart';
import '../../../../core/widgets/figma_field.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../domain/profile.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({required this.isSetup, super.key});

  final bool isSetup;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  String? _imagePath;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(profileProvider.future);
      if (!mounted || _initialized) return;
      _nameController.text = profile?.name ?? '';
      setState(() {
        _imagePath = profile?.imagePath;
        _initialized = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile: $error')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null && mounted) {
        final directory = await getApplicationDocumentsDirectory();
        final profileDirectory = Directory(
          path.join(directory.path, 'profile_images'),
        );
        await profileDirectory.create(recursive: true);
        final extension = path.extension(image.path);
        final savedFile = await File(image.path).copy(
          path.join(
            profileDirectory.path,
            'profile_${DateTime.now().microsecondsSinceEpoch}$extension',
          ),
        );
        if (mounted) setState(() => _imagePath = savedFile.path);
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select an image: $error')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .save(
            Profile(
              name: _nameController.text.trim(),
              imagePath: _imagePath,
              isComplete: true,
            ),
          );
      if (!mounted) return;
      if (widget.isSetup) {
        context.goNamed(RouteNames.home);
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.goNamed(RouteNames.home);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FigmaBackground(
        child: profile.when(
          loading: () => const _ProfileLoading(),
          error: (error, stackTrace) => Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load profile: $error'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(profileProvider);
                        _loadProfile();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              const _ProfileThemeToggle(),
            ],
          ),
          data: (_) => LayoutBuilder(
            builder: (context, constraints) {
              final frameWidth = constraints.maxWidth
                  .clamp(0.0, 375.0)
                  .toDouble();
              return Center(
                child: SizedBox(
                  width: frameWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SafeArea(
                          bottom: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 96),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    height: 40,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          widget.isSetup
                                              ? 'Complete Your Profile'
                                              : 'Profile',
                                          style: AppTextStyles.title.copyWith(
                                            fontSize: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        if (!widget.isSetup)
                                          PositionedDirectional(
                                            start: 0,
                                            child: FigmaBackButton(
                                              onPressed: () => context.pop(),
                                            ),
                                          ),
                                        PositionedDirectional(
                                          end: 0,
                                          child: const AppThemeToggle(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 86),
                                  Text(
                                    'Profile Image',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Center(
                                    child: SizedBox(
                                      width: 165,
                                      height: 165,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          ProfileAvatar(
                                            name: _nameController.text,
                                            imagePath: _imagePath,
                                            radius: 82.5,
                                          ),
                                          if (_imagePath != null)
                                            PositionedDirectional(
                                              end: -3,
                                              bottom: 8,
                                              child: Material(
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                                shape: const CircleBorder(),
                                                child: InkWell(
                                                  customBorder:
                                                      const CircleBorder(),
                                                  onTap: () => setState(
                                                    () => _imagePath = null,
                                                  ),
                                                  child: const SizedBox.square(
                                                    dimension: 38,
                                                    child: Icon(
                                                      Icons.delete_rounded,
                                                      size: 23,
                                                      color: Color(0xFFFF304D),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 34),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _ProfileSourceButton(
                                        label: 'From Camera',
                                        width: 126,
                                        onPressed: () =>
                                            _pickImage(ImageSource.camera),
                                      ),
                                      const SizedBox(width: 12),
                                      _ProfileSourceButton(
                                        label: 'From Gallery',
                                        width: 120,
                                        onPressed: () =>
                                            _pickImage(ImageSource.gallery),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 42),
                                  Text(
                                    'Your Name',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FigmaField(
                                    controller: _nameController,
                                    hintText: 'Your name',
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? 'Enter your name'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 22,
                        end: 22,
                        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                        child: FigmaButton(
                          label: widget.isSetup ? 'Let’s Start!' : 'Save',
                          onPressed: _saving || !_initialized ? null : _save,
                          isLoading: _saving,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileSourceButton extends StatelessWidget {
  const _ProfileSourceButton({
    required this.label,
    required this.width,
    required this.onPressed,
  });

  final String label;
  final double width;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: Material(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) => const Stack(
    children: [
      Center(child: CircularProgressIndicator()),
      _ProfileThemeToggle(),
    ],
  );
}

class _ProfileThemeToggle extends StatelessWidget {
  const _ProfileThemeToggle();

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    top: MediaQuery.of(context).viewPadding.top + 8,
    end: 8,
    child: const AppThemeToggle(),
  );
}
