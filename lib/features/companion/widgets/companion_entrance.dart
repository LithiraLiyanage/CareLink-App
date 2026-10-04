import 'dart:async';

import 'package:flutter/material.dart';

/// A brief page entrance that resolves immediately when motion is disabled.
class CompanionEntrance extends StatefulWidget {
  const CompanionEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<CompanionEntrance> createState() => _CompanionEntranceState();
}

class _CompanionEntranceState extends State<CompanionEntrance>
    with SingleTickerProviderStateMixin {
  Timer? _startTimer;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.025),
    end: Offset.zero,
  ).animate(_opacity);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _startTimer?.cancel();
      _controller.value = 1;
    } else if (_controller.value == 0 && _startTimer == null) {
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        _startTimer = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
