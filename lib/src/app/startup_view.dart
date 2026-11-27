import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:maltto/src/shared/design/app_tokens.dart';

const _startupDuration = Duration(seconds: 2);

final class StartupView extends StatefulWidget {
  const StartupView({
    required this.initialization,
    required this.appBuilder,
    this.duration = _startupDuration,
    super.key,
  });

  final Future<void> initialization;
  final Widget Function() appBuilder;
  final Duration duration;

  @override
  State<StartupView> createState() => _StartupViewState();
}

final class _StartupViewState extends State<StartupView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Widget? _readyApp;
  bool _initializationComplete = false;
  bool _animationComplete = false;
  bool _animationStarted = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleAnimationStatus);
    unawaited(_waitForInitialization());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionPreference();
    if (!_animationStarted) {
      _animationStarted = true;
      _startAnimation();
    }
  }

  @override
  void didChangeAccessibilityFeatures() {
    _syncMotionPreference();
  }

  void _syncMotionPreference() {
    final accessibilityFeatures =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    final reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ??
        false ||
            accessibilityFeatures.disableAnimations ||
            accessibilityFeatures.reduceMotion;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion && _animationStarted && !_animationComplete) {
      _controller.value = 1;
      _markAnimationComplete();
    }
  }

  void _startAnimation() {
    if (_reduceMotion || widget.duration == Duration.zero) {
      _controller.value = 1;
      _markAnimationComplete();
      return;
    }
    unawaited(_controller.forward());
  }

  Future<void> _waitForInitialization() async {
    await widget.initialization;
    if (!mounted) return;
    _initializationComplete = true;
    _showAppIfReady();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _markAnimationComplete();
  }

  void _markAnimationComplete() {
    if (_animationComplete) return;
    _animationComplete = true;
    _showAppIfReady();
  }

  void _showAppIfReady() {
    if (!_initializationComplete || !_animationComplete || !mounted) return;
    setState(() => _readyApp = widget.appBuilder());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readyApp = _readyApp;
    if (readyApp != null) return readyApp;

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.canvas,
      ),
      home: CupertinoPageScaffold(
        child: Center(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                key: const Key('startup-logo'),
                size: const Size.square(256),
                painter: _StartupLogoPainter(progress: _controller.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _StartupLogoPainter extends CustomPainter {
  const _StartupLogoPainter({required this.progress});

  static const _selectionRect = Rect.fromLTWH(15.5, 83.5, 201.5, 89);
  static const _textOriginX = 23.0;
  static const _textBaseline = 155.75;
  static const _cursorStartX = 6.5;
  static const _cursorEndX = 204.0;

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 256;
    canvas.save();
    canvas.scale(scale, scale);

    final cursorX = _cursorStartX + ((_cursorEndX - _cursorStartX) * progress);
    final selectionRight = (cursorX + 11).clamp(
      _selectionRect.left,
      _selectionRect.right,
    );

    _paintWordmark(canvas, AppColors.brand);
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        _selectionRect.left,
        _selectionRect.top,
        selectionRight,
        _selectionRect.bottom,
      ),
    );
    canvas.drawRect(_selectionRect, Paint()..color = AppColors.brand);
    _paintWordmark(canvas, CupertinoColors.white);
    canvas.restore();

    _paintCursor(canvas, cursorX);
    canvas.restore();
  }

  void _paintWordmark(Canvas canvas, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Maltto',
        style: TextStyle(
          color: color,
          fontFamily: 'Arial',
          fontSize: 62,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = textPainter.computeLineMetrics().first.baseline;
    textPainter.paint(canvas, Offset(_textOriginX, _textBaseline - baseline));
  }

  void _paintCursor(Canvas canvas, double x) {
    final path = Path()
      ..moveTo(x, 88)
      ..lineTo(x + 22, 88)
      ..lineTo(x + 22, 95.5)
      ..lineTo(x + 15, 95.5)
      ..lineTo(x + 15, 160.5)
      ..lineTo(x + 22, 160.5)
      ..lineTo(x + 22, 168)
      ..lineTo(x, 168)
      ..lineTo(x, 160.5)
      ..lineTo(x + 7, 160.5)
      ..lineTo(x + 7, 95.5)
      ..lineTo(x, 95.5)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.primaryText);
    canvas.drawPath(
      path,
      Paint()
        ..color = CupertinoColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_StartupLogoPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
