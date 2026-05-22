// main.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

String statusLink = "", updateLink = "", password = "", sendvalue = "", MACaddress = "";

Future<void> loadExisting() async {
  final prefs = await SharedPreferences.getInstance();
  statusLink = prefs.getString("link1") ?? "";
  updateLink = prefs.getString("link2") ?? "";
  MACaddress = prefs.getString("MACaddress") ?? "";
  sendvalue = prefs.getString("sendvalue") ?? "";
  password = prefs.getString("password") ?? "";
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FuturePCControl(),
    );
  }
}

class FuturePCControl extends StatefulWidget {
  const FuturePCControl({super.key});
  @override
  State<FuturePCControl> createState() => _FuturePCControlState();
}

enum SysState { loading, idle, booting, online, error }

class _FuturePCControlState extends State<FuturePCControl>
    with TickerProviderStateMixin {

  SysState sysState = SysState.loading;
  String ipAd = "---.---.--.--";
  String statusText = "LOADING...";
  Color accent = const Color(0xff4D8EFF);

  // Boot: comet spin (fast)
  late AnimationController _bootSpinCtrl;
  // Online: dual spinning arcs (medium speed, opposite directions)
  late AnimationController _fanCtrl1;
  late AnimationController _fanCtrl2;
  // Online: radar ping rings
  late AnimationController _radarCtrl;
  // Idle/Error: rotating dashed ring
  late AnimationController _idleRotateCtrl;
  // Idle/Error: heartbeat glow
  late AnimationController _heartbeatCtrl;

  bool _waking = false;
  bool _polling = false;
  http.Client _client = http.Client();
  Timer? _pollingTimer;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();

    _bootSpinCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    );
    _fanCtrl1 = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    );
    _fanCtrl2 = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    );
    _radarCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    );
    _idleRotateCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    );
    _heartbeatCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    );

    loadExisting().then((_) {
      pollStatus();
      _startPolling();
    });
  }

  void _transition(SysState next, {String? text, Color? color, String? ip}) {
    if (!mounted) return;
    setState(() {
      sysState = next;
      if (text != null) statusText = text;
      if (color != null) accent = color;
      if (ip != null) ipAd = ip;
    });
    _syncAnimations();
  }

  void _syncAnimations() {
    _bootSpinCtrl.stop();
    _fanCtrl1.stop();
    _fanCtrl2.stop();
    _radarCtrl.stop();
    _idleRotateCtrl.stop();
    _heartbeatCtrl.stop();

    switch (sysState) {
      case SysState.booting:
      case SysState.loading:
        _bootSpinCtrl.repeat();
        break;
      case SysState.online:
        _fanCtrl1.repeat();
        _fanCtrl2.repeat();
        _radarCtrl.repeat();
        break;
      case SysState.idle:
      case SysState.error:
        _idleRotateCtrl.repeat();
        _heartbeatCtrl.repeat();
        break;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_waking) pollStatus();
    });
  }

  Future<void> pollStatus() async {
    if (_polling || _waking) return;
    _polling = true;

    try {
      final res = await _client
          .get(Uri.parse("$statusLink?password=$password"))
          .timeout(const Duration(seconds: 6));

      if (!mounted) { _polling = false; return; }

      final data = jsonDecode(res.body);
      final rawMode = data["mode"] as String;
      final newColor = Color(int.parse(
          (data["color"] as String).replaceAll("#", "0xff")));

      _errorCount = 0;

      SysState next;
      switch (rawMode) {
        case "online": next = SysState.online; break;
        case "boot":   next = SysState.booting; break;
        case "idle":   next = SysState.idle; break;
        default:       next = SysState.idle;
      }

      _transition(next,
        text: data["text"] as String,
        color: newColor,
        ip: data["pc_ip"] as String,
      );

    } catch (_) {
      _errorCount++;
      if (_errorCount >= 2) {
        _transition(SysState.error,
          text: "NO SIGNAL",
          color: const Color(0xffFF4D4D),
        );
      }
    }

    _polling = false;
  }

  Future<void> wakePC() async {
    if (_waking || sysState == SysState.booting) return;

    _waking = true;
    _pollingTimer?.cancel();
    _client.close();
    _client = http.Client();
    _polling = false;

    _transition(SysState.booting,
      text: "TRANSMITTING...",
      color: Colors.orange,
    );

    try {
      await _client
          .get(Uri.parse("$updateLink?password=$password&$sendvalue"))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 1));
    _waking = false;

    await pollStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _client.close();
    _bootSpinCtrl.dispose();
    _fanCtrl1.dispose();
    _fanCtrl2.dispose();
    _radarCtrl.dispose();
    _idleRotateCtrl.dispose();
    _heartbeatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = sysState == SysState.booting;
    final bool online   = sysState == SysState.online;
    final bool booting  = sysState == SysState.booting || sysState == SysState.loading;
    final bool idleOrError = sysState == SysState.idle || sysState == SysState.error;

    return Scaffold(
      backgroundColor: const Color(0xff020409),
      drawer: buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white54),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xff0e1620), Color(0xff020409)],
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(8, 12, 18, 0.93),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.10),
                  blurRadius: 70,
                  spreadRadius: 12,
                ),
                const BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Header ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        boxShadow: [BoxShadow(color: accent, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "REMOTE SYSTEM INTERFACE",
                      style: TextStyle(
                        fontSize: 11, letterSpacing: 2.5,
                        color: Color(0xff88AAAA), fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Orb ─────────────────────────────────────
                SizedBox(
                  width: 220, height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // ── ONLINE: Radar ping rings ──────────
                      if (online) ...[
                        _RadarRing(ctrl: _radarCtrl, accent: accent, delay: 0.0),
                        _RadarRing(ctrl: _radarCtrl, accent: accent, delay: 0.33),
                        _RadarRing(ctrl: _radarCtrl, accent: accent, delay: 0.66),
                      ],

                      // ── ONLINE: Fan arc 1 (clockwise) ─────
                      if (online)
                        AnimatedBuilder(
                          animation: _fanCtrl1,
                          builder: (_, __) => Transform.rotate(
                            angle: _fanCtrl1.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(190, 190),
                              painter: _ArcPainter(
                                color: accent,
                                strokeWidth: 3.0,
                                opacity: 0.85,
                                // 3 arcs evenly spaced, each 80° wide
                                arcs: [
                                  (startAngle: 0.0,         sweepAngle: pi * 0.44),
                                  (startAngle: pi * 2 / 3,  sweepAngle: pi * 0.44),
                                  (startAngle: pi * 4 / 3,  sweepAngle: pi * 0.44),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── ONLINE: Fan arc 2 (counter-clockwise, different radius) ──
                      if (online)
                        AnimatedBuilder(
                          animation: _fanCtrl2,
                          builder: (_, __) => Transform.rotate(
                            angle: -_fanCtrl2.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(155, 155),
                              painter: _ArcPainter(
                                color: accent,
                                strokeWidth: 2.0,
                                opacity: 0.5,
                                arcs: [
                                  (startAngle: pi * 0.2,       sweepAngle: pi * 0.33),
                                  (startAngle: pi * 0.2 + pi * 2 / 3, sweepAngle: pi * 0.33),
                                  (startAngle: pi * 0.2 + pi * 4 / 3, sweepAngle: pi * 0.33),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── BOOT: Comet spin ──────────────────
                      if (booting)
                        AnimatedBuilder(
                          animation: _bootSpinCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: _bootSpinCtrl.value * 2 * pi,
                            child: Container(
                              width: 180, height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  accent.withOpacity(0.0),
                                  accent.withOpacity(0.9),
                                  accent.withOpacity(0.3),
                                  accent.withOpacity(0.0),
                                ]),
                              ),
                            ),
                          ),
                        ),

                      // ── IDLE/ERROR: Rotating dashed ring ──
                      if (idleOrError)
                        AnimatedBuilder(
                          animation: _idleRotateCtrl,
                          builder: (_, __) => Transform.rotate(
                            angle: _idleRotateCtrl.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(185, 185),
                              painter: _DashedRingPainter(
                                color: accent,
                                dashCount: 12,
                                strokeWidth: 2.5,
                                opacity: 0.7,
                              ),
                            ),
                          ),
                        ),

                      // ── IDLE/ERROR: Heartbeat glow ring ───
                      if (idleOrError)
                        AnimatedBuilder(
                          animation: _heartbeatCtrl,
                          builder: (_, __) {
                            final t = _heartbeatCtrl.value;
                            double pulse = 0;
                            if (t < 0.12)      pulse = t / 0.12;
                            else if (t < 0.22) pulse = 1 - (t - 0.12) / 0.10;
                            else if (t < 0.32) pulse = (t - 0.22) / 0.10 * 0.7;
                            else if (t < 0.42) pulse = 0.7 - (t - 0.32) / 0.10 * 0.7;
                            return Container(
                              width: 185, height: 185,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withOpacity(0.25 + pulse * 0.65),
                                  width: 2 + pulse * 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(pulse * 0.4),
                                    blurRadius: 18 + pulse * 20,
                                    spreadRadius: pulse * 6,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      // ── Static outer ring ─────────────────
                      Container(
                        width: 170, height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withOpacity(0.12), width: 1,
                          ),
                        ),
                      ),

                      // ── Inner core + icon ─────────────────
                      AnimatedBuilder(
                        animation: online ? _fanCtrl1 : _heartbeatCtrl,
                        builder: (_, child) {
                          final glow = online ? 0.35 : 0.1;
                          return Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xff05080d),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(glow),
                                  blurRadius: online ? 30 : 16,
                                  spreadRadius: online ? 6 : -2,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Icon(
                              _orbIcon(),
                              key: ValueKey(sysState),
                              color: accent.withOpacity(0.85),
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Status text ──────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: accent, letterSpacing: 2,
                      shadows: [Shadow(color: accent.withOpacity(0.5), blurRadius: 14)],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    ipAd,
                    key: ValueKey(ipAd),
                    style: TextStyle(
                      fontSize: 11, letterSpacing: 2,
                      color: Colors.grey[700], fontFamily: 'monospace',
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: disabled ? null : wakePC,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: disabled
                          ? const Color(0xff0a0e14)
                          : const Color(0xff1a2030),
                      side: BorderSide(
                        color: disabled
                            ? Colors.white.withOpacity(0.04)
                            : accent.withOpacity(0.35),
                        width: 1,
                      ),
                      elevation: 0,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _buttonLabel(),
                        key: ValueKey(sysState),
                        style: TextStyle(
                          letterSpacing: 2, fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: disabled ? Colors.grey[800] : accent,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Footer ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: online
                            ? const Color(0xff44ff88)
                            : sysState == SysState.error
                                ? const Color(0xffFF4D4D)
                                : Colors.grey[800]!,
                        boxShadow: online
                            ? [const BoxShadow(color: Color(0xff44ff88), blurRadius: 6)]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Live status · Auto sync · ${_stateLabel()}",
                      style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.grey[700]),
                    ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _orbIcon() {
    switch (sysState) {
      case SysState.online:  return Icons.computer_rounded;
      case SysState.booting:
      case SysState.loading: return Icons.wifi_tethering_rounded;
      case SysState.error:   return Icons.signal_wifi_statusbar_connected_no_internet_4_rounded;
      default:               return Icons.power_settings_new_rounded;
    }
  }

  String _buttonLabel() {
    switch (sysState) {
      case SysState.booting:
      case SysState.loading: return "CONNECTING...";
      case SysState.online:  return "RECONNECT";
      default:               return "POWER ON";
    }
  }

  String _stateLabel() {
    switch (sysState) {
      case SysState.online:  return "ONLINE";
      case SysState.booting: return "BOOTING";
      case SysState.error:   return "NO SIGNAL";
      case SysState.loading: return "LOADING";
      default:               return "STANDBY";
    }
  }
}

// ── Radar ring (expanding + fading ping) ──────────────────────
class _RadarRing extends StatelessWidget {
  final AnimationController ctrl;
  final Color accent;
  final double delay;

  const _RadarRing({required this.ctrl, required this.accent, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value + delay) % 1.0);
        final scale = 0.3 + t * 0.7;      // grows from 30% to 100% of 220px
        final opacity = (1.0 - t) * 0.7;  // fades as it expands
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withOpacity(opacity),
                width: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Arc painter (CPU fan blades) ──────────────────────────────
typedef _ArcDef = ({double startAngle, double sweepAngle});

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double opacity;
  final List<_ArcDef> arcs;

  _ArcPainter({
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.arcs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final arc in arcs) {
      canvas.drawArc(rect, arc.startAngle, arc.sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

// ── Dashed ring painter (idle) ────────────────────────────────
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  final double opacity;

  _DashedRingPainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dashAngle = (2 * pi) / dashCount;
    final gapFraction = 0.4; // 40% gap between dashes

    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      final sweep = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, sweep, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}