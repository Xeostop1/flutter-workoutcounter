import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class FlameArtwork {
  static const stages = [-2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const colors = [
    Color(0xFF4E4541),
    Color(0xFF645349),
    Color(0xFFA5684B),
    Color(0xFFCE794E),
    Color(0xFFDC985A),
    Color(0xFFE4AD6C),
    Color(0xFFF2BA73),
    Color(0xFFF9D18B),
    Color(0xFFFFE082),
    Color(0xFFFFE38A),
    Color(0xFFFFE58C),
    Color(0xFFF2DCA0),
    Color(0xFFF4DFAA),
  ];

  static int index(int stage) => stage.clamp(-2, 10) + 2;
  static String asset(int stage) =>
      'assets/images/flames_v2/stage-${(index(stage) + 1).toString().padLeft(2, '0')}.png';
}

/// The approved GIF motion, rendered from its high-resolution transparent PNG.
class FlameAvatar extends StatefulWidget {
  const FlameAvatar({
    super.key,
    required this.stage,
    required this.size,
    this.animate = true,
    this.characterScale = 1,
  });

  final int stage;
  final double size;
  final bool animate;
  final double characterScale;

  @override
  State<FlameAvatar> createState() => _FlameAvatarState();
}

class _FlameAvatarState extends State<FlameAvatar>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _visible = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible =
        TickerMode.of(context) && !MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant FlameAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _syncMotion() {
    if (_visible && _foreground && widget.animate) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage.clamp(-2, 10);
    final image = Image.asset(
      FlameArtwork.asset(stage),
      key: ValueKey('flame-art-$stage'),
      width: widget.size,
      height: widget.size,
      cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context))
          .ceil()
          .clamp(1, 1024),
      filterQuality: FilterQuality.medium,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _motion,
          child: image,
          builder: (_, child) {
            final wave = math.sin(_motion.value * math.pi * 2);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _FlameBackdrop(stage, wave)),
                ),
                Transform.translate(
                  offset: Offset(0, widget.size * (-.016 - .0094 * wave)),
                  child: Transform.rotate(
                    angle: wave * math.pi / 400,
                    alignment: const Alignment(0, .64),
                    child: Transform.scale(
                      alignment: const Alignment(0, .64),
                      scaleX: widget.characterScale * (1 + .014 * wave),
                      scaleY: widget.characterScale * (1 + .018 * wave),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FlameBackdrop extends CustomPainter {
  const _FlameBackdrop(this.stage, this.wave);
  final int stage;
  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final color = FlameArtwork.colors[FlameArtwork.index(stage)];
    final center = Offset(s * .5, s * .47);
    final glow = (stage < 0 ? .08 : .23) + wave * .025;
    final halo = Rect.fromCircle(center: center, radius: s * .49);
    canvas.drawCircle(
      center,
      s * .49,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: glow),
            color.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );
    final disc = Rect.fromCircle(center: center, radius: s * .39);
    canvas.drawCircle(
      center,
      s * .39,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: .94),
            const Color(0xFF79646C).withValues(alpha: .65),
          ],
        ).createShader(disc),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * .5, s * .86),
        width: s * .65,
        height: s * .06,
      ),
      Paint()
        ..color = color.withValues(alpha: glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .035),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * .5, s * .87),
        width: s * (.4 - wave * .01),
        height: s * .025,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .015),
    );
  }

  @override
  bool shouldRepaint(covariant _FlameBackdrop oldDelegate) =>
      stage != oldDelegate.stage || wave != oldDelegate.wave;
}
