import 'package:flutter/material.dart';

/// A Column that staggers its children with fade+slide-up entrance animations.
/// Each child appears after a delay based on its index.
class StaggeredColumn extends StatefulWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration totalDuration;
  final Duration staggerDelay;

  const StaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.totalDuration = const Duration(milliseconds: 1800),
    this.staggerDelay = const Duration(milliseconds: 120),
  });

  @override
  State<StaggeredColumn> createState() => _StaggeredColumnState();
}

class _StaggeredColumnState extends State<StaggeredColumn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.totalDuration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    final totalMs = widget.totalDuration.inMilliseconds;

    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: List.generate(count, (i) {
        final double startFraction = totalMs > 0
            ? ((i * widget.staggerDelay.inMilliseconds) / totalMs).clamp(0.0, 1.0)
            : 0.0;
        final double endFraction = totalMs > 0
            ? (((i * widget.staggerDelay.inMilliseconds) + 600) / totalMs).clamp(0.0, 1.0)
            : 1.0;

        final double begin = startFraction.isNaN ? 0.0 : startFraction;
        final double end = endFraction.isNaN ? 1.0 : (endFraction < begin ? begin : endFraction);

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            begin,
            end,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}
