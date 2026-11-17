import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottie extends StatefulWidget {
  const AppLottie({
    required this.assetPath,
    this.height = 180,
    this.width,
    this.repeat = true,
    this.onCompleted,
    super.key,
  });

  final String assetPath;
  final double height;
  final double? width;
  final bool repeat;
  final VoidCallback? onCompleted;

  @override
  State<AppLottie> createState() => _AppLottieState();
}

class _AppLottieState extends State<AppLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;
  bool _errorReported = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  void _start(LottieComposition composition) {
    _controller.duration = composition.duration;
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: Lottie.asset(
        widget.assetPath,
        controller: _controller,
        animate: false,
        repeat: false,
        onLoaded: _start,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Builder(
            builder: (context) {
              if (!_errorReported) {
                _errorReported = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _finish();
                });
              }
              return Text(
                'Animation unavailable: ${widget.assetPath}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
        ),
      ),
    );
  }
}
