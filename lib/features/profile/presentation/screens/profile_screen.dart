import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? 'Complete Your Profile' : 'Profile'),
        leading: widget.isSetup
            ? null
            : IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
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
        data: (_) => SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                  children: [
                    Text(
                      'Profile Image',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _imagePath == null
                              ? ProfileAvatar(
                                  name: _nameController.text,
                                  radius: 76,
                                )
                              : CircleAvatar(
                                  radius: 76,
                                  child: ClipOval(
                                    child: Image.file(
                                      File(_imagePath!),
                                      width: 152,
                                      height: 152,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.person_outline,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                    ),
                                  ),
                                ),
                          if (_imagePath != null)
                            IconButton.filled(
                              onPressed: () =>
                                  setState(() => _imagePath = null),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remove profile image',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('From Camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('From Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Your Name',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Your name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your name'
                          : null,
                    ),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: _saving || !_initialized ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isSetup ? 'Let’s Start!' : 'Save'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your profile is stored on this device.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
