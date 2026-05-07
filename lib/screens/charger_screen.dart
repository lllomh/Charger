import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import '../models/particle.dart';
import '../painters/particle_painter.dart';
import '../providers/battery_provider.dart';
import '../services/foreground_task_handler.dart';

const _kioskChannel = MethodChannel('com.henry.charger/kiosk');

class ChargerScreen extends StatefulWidget {
  const ChargerScreen({super.key});

  @override
  State<ChargerScreen> createState() => _ChargerScreenState();
}

class _ChargerScreenState extends State<ChargerScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _breathController;

  final List<Particle> _particles = [];
  final Random _rng = Random();
  Size _screenSize = Size.zero;

  static const int _maxParticles = 120;
  static const double _spawnRate = 30;
  double _spawnAccumulator = 0.0;
  Duration? _lastTick;

  Timer? _exitHoldTimer;
  double _exitProgress = 0.0;
  Timer? _progressTicker;

  Timer? _fractionTimer;
  String _fractionDigits = '0000000';
  double? _finePercent;
  bool? _fineSupported;

  Timer? _powerTimer;
  double? _powerWatts;

  int _debugTapCount = 0;
  DateTime _lastDebugTap = DateTime(0);

  static const _rotFastDuration = Duration(seconds: 4);
  static const _rotSlowDuration = Duration(seconds: 20);
  static const _breathFastDuration = Duration(milliseconds: 2400);
  static const _breathSlowDuration = Duration(milliseconds: 6000);

  BatteryProvider? _battery;
  bool _lastIsCharging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: _rotSlowDuration,
    )..repeat();
    _breathController = AnimationController(
      vsync: this,
      duration: _breathSlowDuration,
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(_onTick)
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startService();
      _enableKiosk();
      _battery = context.read<BatteryProvider>()..addListener(_onBatteryChanged);
      _onBatteryChanged();
    });
  }

  void _onBatteryChanged() {
    final isCharging = _battery?.isCharging ?? false;
    if (isCharging == _lastIsCharging) return;
    _lastIsCharging = isCharging;

    if (isCharging) {
      _rotationController
        ..duration = _rotFastDuration
        ..repeat();
      _breathController
        ..duration = _breathFastDuration
        ..repeat(reverse: true);
      _startReadingTimer();
      _startPowerTimer();
    } else {
      _rotationController
        ..duration = _rotSlowDuration
        ..repeat();
      _breathController
        ..duration = _breathSlowDuration
        ..repeat(reverse: true);
      _fractionTimer?.cancel();
      _fractionTimer = null;
      _powerTimer?.cancel();
      _powerTimer = null;
      setState(() {
        _fractionDigits = '0000000';
        _finePercent = null;
        _powerWatts = null;
      });
    }
  }

  Future<void> _startReadingTimer() async {
    if (_fineSupported == null) {
      final pct = await _readFinePercent();
      _fineSupported = pct != null;
      if (pct != null && mounted) {
        setState(() => _finePercent = pct);
      }
    }
    _fractionTimer?.cancel();
    final period = _fineSupported == true
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 80);
    _fractionTimer = Timer.periodic(period, (_) => _tickFraction());
  }

  Future<double?> _readFinePercent() async {
    try {
      return await _kioskChannel.invokeMethod<double>('getFinePercent');
    } on PlatformException {
      return null;
    }
  }

  Future<void> _tickFraction() async {
    if (_fineSupported == true) {
      final pct = await _readFinePercent();
      if (pct != null && mounted) {
        setState(() => _finePercent = pct);
      }
      return;
    }
    final buf = StringBuffer();
    for (var i = 0; i < 7; i++) {
      buf.write(_rng.nextInt(10));
    }
    if (mounted) setState(() => _fractionDigits = buf.toString());
  }

  void _startPowerTimer() {
    _updatePower();
    _powerTimer?.cancel();
    _powerTimer = Timer.periodic(const Duration(seconds: 2), (_) => _updatePower());
  }

  Future<void> _showPowerDebug() async {
    try {
      final info = await _kioskChannel.invokeMethod<String>('getPowerDebug');
      if (!mounted || info == null) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0A1628),
          title: const Text('Power Debug', style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
          content: SingleChildScrollView(
            child: Text(info, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭', style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      );
    } on PlatformException {/* ignore */}
  }

  Future<void> _updatePower() async {
    try {
      final w = await _kioskChannel.invokeMethod<double>('getPowerWatts');
      if (w != null && mounted) setState(() => _powerWatts = w);
    } on PlatformException {
      // not supported on this device
    }
  }

  Future<void> _startService() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: '正在充电',
      notificationText: '充电动画运行中',
      callback: startCallback,
    );
  }

  Future<void> _enableKiosk() async {
    try {
      await _kioskChannel.invokeMethod<bool>('startKiosk');
    } on PlatformException {
      // 屏幕固定未在系统设置中启用
    }
  }

  void _handlePointerDown() {
    final now = DateTime.now();
    if (now.difference(_lastDebugTap) < const Duration(milliseconds: 500)) {
      _debugTapCount++;
      if (_debugTapCount >= 6) {
        _debugTapCount = 0;
        _showPowerDebug();
        return;
      }
    } else {
      _debugTapCount = 1;
    }
    _lastDebugTap = now;
    _onHoldStart();
  }

  void _onHoldStart() {
    _exitHoldTimer?.cancel();
    _progressTicker?.cancel();
    final startTime = DateTime.now();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      setState(() {
        _exitProgress = (elapsed / 3000).clamp(0.0, 1.0);
      });
    });
    _exitHoldTimer = Timer(const Duration(seconds: 3), () async {
      _progressTicker?.cancel();
      setState(() => _exitProgress = 0.0);
      try {
        await _kioskChannel.invokeMethod('requestExit');
      } on PlatformException {
        // ignore
      }
    });
  }

  void _onHoldCancel() {
    _exitHoldTimer?.cancel();
    _progressTicker?.cancel();
    if (_exitProgress > 0) {
      setState(() => _exitProgress = 0.0);
    }
  }

  void _onTick() {
    final elapsed = _particleController.lastElapsedDuration;
    if (elapsed == null || _screenSize == Size.zero) return;

    final dt = _lastTick == null
        ? 0.016
        : (elapsed - _lastTick!).inMicroseconds / 1e6;
    _lastTick = elapsed;

    _updateParticles(dt.clamp(0.0, 0.05));
  }

  void _updateParticles(double dt) {
    final size = _screenSize;
    final center = ParticlePainter.circleCenter(size);
    const radius = ParticlePainter.circleRadius;
    final isCharging = context.read<BatteryProvider>().isCharging;

    if (!isCharging) {
      if (_particles.isNotEmpty) {
        _particles.clear();
        _spawnAccumulator = 0.0;
        setState(() {});
      }
      return;
    }

    _spawnAccumulator += _spawnRate * dt;
    while (_spawnAccumulator >= 1.0 && _particles.length < _maxParticles) {
      _particles.add(Particle.spawn(size, _rng));
      _spawnAccumulator -= 1.0;
    }

    final toRemove = <Particle>[];
    for (final p in _particles) {
      final toCenter = center - p.position;
      final dist = toCenter.distance;

      final dir = toCenter / dist;
      final desiredVel = dir * (p.speed * 1.5);
      p.velocity += (desiredVel - p.velocity) * (4.0 * dt);
      p.velocity = _clampOffset(p.velocity, 260);

      p.position += p.velocity * dt;

      final newDist = (p.position - center).distance;
      if (newDist < radius * 1.3) {
        p.opacity = ((newDist - radius) / (radius * 0.3)).clamp(0.0, 1.0);
      }

      if (newDist <= radius) {
        toRemove.add(p);
        _pulseController.forward(from: 0.0);
      }
    }

    _particles.removeWhere(toRemove.contains);
    setState(() {});
  }

  Offset _clampOffset(Offset o, double max) {
    final mag = o.distance;
    if (mag > max) return o / mag * max;
    return o;
  }

  @override
  void dispose() {
    _battery?.removeListener(_onBatteryChanged);
    _exitHoldTimer?.cancel();
    _progressTicker?.cancel();
    _fractionTimer?.cancel();
    _powerTimer?.cancel();
    _particleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF050D18),
        body: Listener(
          onPointerDown: (_) => _handlePointerDown(),
          onPointerUp: (_) => _onHoldCancel(),
          onPointerCancel: (_) => _onHoldCancel(),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (ctx, constraints) {
                  _screenSize =
                      Size(constraints.maxWidth, constraints.maxHeight);
                  return AnimatedBuilder(
                    animation: Listenable.merge([
                      _particleController,
                      _pulseController,
                      _rotationController,
                      _breathController,
                    ]),
                    builder: (context, _) {
                      final battery = context.watch<BatteryProvider>();
                      final text = !battery.isCharging
                          ? '${battery.level}%'
                          : (_finePercent != null
                              ? '${_finePercent!.toStringAsFixed(2)}%'
                              : '${battery.level}.$_fractionDigits%');
                      return CustomPaint(
                        painter: ParticlePainter(
                          particles: List.of(_particles),
                          displayText: text,
                          powerWatts: _powerWatts,
                          glowPulse: _pulseController.value,
                          rotation: _rotationController.value * 2 * math.pi,
                          breath: _breathController.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  );
                },
              ),
              if (_exitProgress > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 80,
                  child: Column(
                    children: [
                      Text(
                        '继续长按退出…',
                        style: TextStyle(
                          color: Colors.white
                              .withValues(alpha: 0.7 + _exitProgress * 0.3),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          value: _exitProgress,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.cyanAccent),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Center(
                  child: Text(
                    '长按屏幕 3 秒退出',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
