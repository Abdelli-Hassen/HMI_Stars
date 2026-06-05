import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppToastType { success, error, info }

class ToastItem {
  final String id;
  final String message;
  final AppToastType type;

  ToastItem({
    required this.id,
    required this.message,
    required this.type,
  });
}

class AppToast extends StatefulWidget {
  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;

  const AppToast({
    super.key,
    required this.message,
    this.type = AppToastType.info,
    required this.onDismiss,
  });

  static OverlayEntry? _overlayEntry;
  static final List<ToastItem> _activeToasts = [];
  static final ValueNotifier<List<ToastItem>> _toastsNotifier = ValueNotifier([]);

  static void show(BuildContext context, String message, {AppToastType type = AppToastType.info}) {
    final toast = ToastItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_$message',
      message: message,
      type: type,
    );

    _activeToasts.add(toast);
    _toastsNotifier.value = List.from(_activeToasts);

    if (_overlayEntry == null) {
      final overlayState = Overlay.of(context);
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: ValueListenableBuilder<List<ToastItem>>(
              valueListenable: _toastsNotifier,
              builder: (context, toasts, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: toasts.map((t) {
                    return KeyedSubtree(
                      key: ValueKey(t.id),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: AppToast(
                          message: t.message,
                          type: t.type,
                          onDismiss: () {
                            _activeToasts.removeWhere((item) => item.id == t.id);
                            _toastsNotifier.value = List.from(_activeToasts);
                            if (_activeToasts.isEmpty) {
                              _overlayEntry?.remove();
                              _overlayEntry = null;
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );
      overlayState.insert(_overlayEntry!);
    }
  }

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 4), () {
      _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _getBgColor() {
    switch (widget.type) {
      case AppToastType.success:
        return AppColors.successLight;
      case AppToastType.error:
        return AppColors.errorContainer;
      case AppToastType.info:
        return AppColors.infoLight;
    }
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case AppToastType.success:
        return AppColors.success;
      case AppToastType.error:
        return AppColors.error;
      case AppToastType.info:
        return AppColors.info;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor();
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 380,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _getBgColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _getIcon(),
                color: accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close_rounded, size: 18, color: AppColors.outline),
                onPressed: _dismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
