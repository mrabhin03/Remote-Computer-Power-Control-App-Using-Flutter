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

// ── Animation IDs ─────────────────────────────────────────────
// Default per state:
//   loading/booting → "comet"
//   online          → "fan+radar"
//   idle            → "dashed+heartbeat"
//   error           → "dashed+heartbeat"
//
// Server can override via 'animation' field with any key below.
const Map<String, String> _animDefaults = {
  'loading': 'comet',
  'booting': 'comet',
  'online':  'fan_radar',
  'idle':    'dashed_hb',
  'error':   'dashed_hb',
};

class _FuturePCControlState extends State<FuturePCControl>
    with TickerProviderStateMixin {

  SysState sysState = SysState.loading;
  String ipAd       = "---.---.--.--";
  String statusText = "LOADING...";
  Color  accent     = const Color(0xff4D8EFF);
  String _animId    = 'comet'; // currently playing animation

  // ── Controllers ───────────────────────────────────────────
  late AnimationController _spinA;   // generic fast spin CW
  late AnimationController _spinB;   // generic medium spin CCW
  late AnimationController _spinC;   // generic slow spin CW
  late AnimationController _pulseA;  // 0→1→0 slow (1.5s)
  late AnimationController _pulseB;  // heartbeat (1.2s)
  late AnimationController _ripple;  // ripple/radar (2s)
  late AnimationController _wave;    // wave sweep (3s)

  bool _waking      = false;
  bool _polling     = false;
  http.Client _client = http.Client();
  Timer? _pollingTimer;
  int _errorCount   = 0;

  @override
  void initState() {
    super.initState();
    _spinA  = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _spinB  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _spinC  = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _pulseA = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseB = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ripple = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _wave   = AnimationController(vsync: this, duration: const Duration(seconds: 3));

    loadExisting().then((_) {
      pollStatus();
      _startPolling();
    });
  }

  // ── Stop everything ───────────────────────────────────────
  void _stopAll() {
    for (final c in [_spinA, _spinB, _spinC, _pulseA, _pulseB, _ripple, _wave]) {
      c.stop();
      c.reset();
    }
  }

  // ── Play animation by ID ──────────────────────────────────
  void _playAnim(String id) {
    _stopAll();
    _animId = id;
    switch (id) {

      // ── DEFAULT BOOT: comet sweep ─────────────────────────
      case 'comet':
        _spinA.repeat();
        break;

      // ── DEFAULT ONLINE: fan arcs + radar ─────────────────
      case 'fan_radar':
        _spinA.repeat();
        _spinB.repeat();
        _ripple.repeat();
        break;

      // ── DEFAULT IDLE/ERROR: dashed ring + heartbeat ───────
      case 'dashed_hb':
        _spinC.repeat();
        _pulseB.repeat();
        break;

      // ── EXTRA 1: triple ripple only ───────────────────────
      case 'ripple3':
        _ripple.repeat();
        break;

      // ── EXTRA 2: double counter-spin ──────────────────────
      case 'dual_spin':
        _spinA.repeat();
        _spinB.repeat();
        break;

      // ── EXTRA 3: slow breathe pulse ───────────────────────
      case 'breathe':
        _pulseA.repeat(reverse: true);
        break;

      // ── EXTRA 4: wave + slow spin ─────────────────────────
      case 'wave_spin':
        _wave.repeat();
        _spinC.repeat();
        break;

      // ── EXTRA 5: fast spin only ───────────────────────────
      case 'spin_fast':
        _spinA.repeat();
        break;

      // ── EXTRA 6: heartbeat only ───────────────────────────
      case 'heartbeat':
        _pulseB.repeat();
        break;

      // ── EXTRA 7: radar + breathe ──────────────────────────
      case 'radar_breathe':
        _ripple.repeat();
        _pulseA.repeat(reverse: true);
        break;

      // ── EXTRA 8: all rings spinning (chaos) ───────────────
      case 'chaos':
        _spinA.repeat();
        _spinB.repeat();
        _spinC.repeat();
        _ripple.repeat();
        break;

      // ── EXTRA 9: wave sweep only ──────────────────────────
      case 'wave':
        _wave.repeat();
        break;

      // ── EXTRA 10: slow orbit ──────────────────────────────
      case 'orbit':
        _spinC.repeat();
        _ripple.repeat();
        break;

      // ── EXTRA 11: pulse burst (fast pulse + radar) ────────
      case 'pulse_burst':
        _pulseA.repeat(reverse: true);
        _ripple.repeat();
        break;

      // ── EXTRA 12: twin fan (same dir, different speed) ────
      case 'twin_fan':
        _spinA.repeat();
        _spinC.repeat();
        break;

      // ── EXTRA 13: sonar (ripple + single slow spin) ───────
      case 'sonar':
        _ripple.repeat();
        _spinC.repeat();
        break;

      // ── EXTRA 14: idle drift (very slow spin, no pulse) ───
      case 'drift':
        _spinC.repeat();
        break;

      // ── EXTRA 15: strobe pulse ────────────────────────────
      case 'strobe':
        _pulseB.repeat();
        _spinA.repeat();
        break;

      // ── EXTRA 16: electric (fast + wave) ─────────────────
      case 'electric':
        _spinA.repeat();
        _wave.repeat();
        _pulseB.repeat();
        break;

      // ── EXTRA 17: matrix (wave + ripple) ─────────────────
      case 'matrix':
        _wave.repeat();
        _ripple.repeat();
        break;

      // ── EXTRA 18: zen (breathe only, very slow) ───────────
      case 'zen':
        _pulseA.repeat(reverse: true);
        break;

      // ── EXTRA 19: vortex (all spins, no ripple) ───────────
      case 'vortex':
        _spinA.repeat();
        _spinB.repeat();
        _spinC.repeat();
        break;

      // ── EXTRA 20: nova (everything at once) ───────────────
      case 'nova':
        _spinA.repeat();
        _spinB.repeat();
        _spinC.repeat();
        _pulseA.repeat(reverse: true);
        _pulseB.repeat();
        _ripple.repeat();
        _wave.repeat();
        break;

      default:
        // fallback to state default
        _playAnim(_animDefaults[sysState.name] ?? 'comet');
    }
  }

  // ── State transition ──────────────────────────────────────
  void _transition(SysState next, {String? text, Color? color, String? ip, String? animOverride}) {
    if (!mounted) return;
    setState(() {
      sysState = next;
      if (text != null)  statusText = text;
      if (color != null) accent     = color;
      if (ip != null)    ipAd       = ip;
    });
    final id = (animOverride != null && animOverride.isNotEmpty)
        ? animOverride
        : _animDefaults[next.name] ?? 'comet';
    _playAnim(id);
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

      final data      = jsonDecode(res.body);
      final rawMode   = data["mode"] as String;
      final newColor  = Color(int.parse(
          (data["color"] as String).replaceAll("#", "0xff")));
      final animOver  = (data["animation"] as String?) ?? "";

      _errorCount = 0;

      SysState next;
      switch (rawMode) {
        case "online": next = SysState.online;  break;
        case "boot":   next = SysState.booting; break;
        case "idle":   next = SysState.idle;    break;
        default:       next = SysState.idle;
      }

      _transition(next,
        text:         data["text"] as String,
        color:        newColor,
        ip:           data["pc_ip"] as String,
        animOverride: animOver,
      );

    } catch (_) {
      _errorCount++;
      if (_errorCount >= 2) {
        _transition(SysState.error, text: "NO SIGNAL", color: const Color(0xffFF4D4D));
      }
    }

    _polling = false;
  }

  Future<void> wakePC() async {
    if (_waking || sysState == SysState.booting) return;

    _waking = true;
    _pollingTimer?.cancel();
    _client.close();
    _client  = http.Client();
    _polling = false;

    _transition(SysState.booting, text: "TRANSMITTING...", color: Colors.orange);

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
    for (final c in [_spinA, _spinB, _spinC, _pulseA, _pulseB, _ripple, _wave]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool disabled    = sysState == SysState.booting;
    final bool online      = sysState == SysState.online;
    final bool booting     = sysState == SysState.booting || sysState == SysState.loading;
    final bool idleOrError = sysState == SysState.idle || sysState == SysState.error;

    return Scaffold(
      backgroundColor: const Color(0xff020409),
      drawer: buildDrawer(context, current: DrawerPage.home, liveState: sysState),
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
                BoxShadow(color: accent.withOpacity(0.10), blurRadius: 70, spreadRadius: 12),
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

                      // ── Ripple rings (radar / ripple3 / pulse_burst / orbit / sonar / matrix) ──
                      if (_uses(_animId, 'ripple'))
                        ...[0.0, 0.33, 0.66].map((d) =>
                          _RadarRing(ctrl: _ripple, accent: accent, delay: d)),

                      // ── Wave sweep ────────────────────────
                      if (_uses(_animId, 'wave'))
                        AnimatedBuilder(
                          animation: _wave,
                          builder: (_, __) => Transform.rotate(
                            angle: _wave.value * 2 * pi,
                            child: Container(
                              width: 195, height: 195,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  accent.withOpacity(0.0),
                                  accent.withOpacity(0.5),
                                  accent.withOpacity(0.15),
                                  accent.withOpacity(0.0),
                                ]),
                              ),
                            ),
                          ),
                        ),

                      // ── Fan arc 1 (CW) — spinA ────────────
                      if (_uses(_animId, 'spinA'))
                        AnimatedBuilder(
                          animation: _spinA,
                          builder: (_, __) => Transform.rotate(
                            angle: _spinA.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(190, 190),
                              painter: _ArcPainter(
                                color: accent, strokeWidth: 3.0, opacity: 0.85,
                                arcs: [
                                  (startAngle: 0.0,        sweepAngle: pi * 0.44),
                                  (startAngle: pi * 2 / 3, sweepAngle: pi * 0.44),
                                  (startAngle: pi * 4 / 3, sweepAngle: pi * 0.44),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── Comet ring — spinA at full opacity ─
                      if (_animId == 'comet' || _animId == 'strobe' || _animId == 'electric')
                        AnimatedBuilder(
                          animation: _spinA,
                          builder: (_, __) => Transform.rotate(
                            angle: _spinA.value * 2 * pi,
                            child: Container(
                              width: 180, height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(colors: [
                                  accent.withOpacity(0.0),
                                  accent.withOpacity(0.95),
                                  accent.withOpacity(0.35),
                                  accent.withOpacity(0.0),
                                ]),
                              ),
                            ),
                          ),
                        ),

                      // ── Fan arc 2 (CCW) — spinB ───────────
                      if (_uses(_animId, 'spinB'))
                        AnimatedBuilder(
                          animation: _spinB,
                          builder: (_, __) => Transform.rotate(
                            angle: -_spinB.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(155, 155),
                              painter: _ArcPainter(
                                color: accent, strokeWidth: 2.0, opacity: 0.5,
                                arcs: [
                                  (startAngle: pi * 0.2,                  sweepAngle: pi * 0.33),
                                  (startAngle: pi * 0.2 + pi * 2 / 3,    sweepAngle: pi * 0.33),
                                  (startAngle: pi * 0.2 + pi * 4 / 3,    sweepAngle: pi * 0.33),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── Slow spin / dashed ring — spinC ───
                      if (_uses(_animId, 'spinC'))
                        AnimatedBuilder(
                          animation: _spinC,
                          builder: (_, __) => Transform.rotate(
                            angle: _spinC.value * 2 * pi,
                            child: CustomPaint(
                              size: const Size(185, 185),
                              painter: _DashedRingPainter(
                                color: accent, dashCount: 12,
                                strokeWidth: 2.5, opacity: 0.65,
                              ),
                            ),
                          ),
                        ),

                      // ── Breathe glow ring — pulseA ────────
                      if (_uses(_animId, 'pulseA'))
                        AnimatedBuilder(
                          animation: _pulseA,
                          builder: (_, __) {
                            final v = _pulseA.value;
                            return Container(
                              width: 185, height: 185,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withOpacity(0.1 + v * 0.6),
                                  width: 1.5 + v * 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(v * 0.5),
                                    blurRadius: 20 + v * 30,
                                    spreadRadius: v * 8,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      // ── Heartbeat glow ring — pulseB ──────
                      if (_uses(_animId, 'pulseB'))
                        AnimatedBuilder(
                          animation: _pulseB,
                          builder: (_, __) {
                            final t = _pulseB.value;
                            double pulse = 0;
                            if      (t < 0.12) pulse = t / 0.12;
                            else if (t < 0.22) pulse = 1 - (t - 0.12) / 0.10;
                            else if (t < 0.32) pulse = (t - 0.22) / 0.10 * 0.7;
                            else if (t < 0.42) pulse = 0.7 - (t - 0.32) / 0.10 * 0.7;
                            return Container(
                              width: 185, height: 185,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withOpacity(0.2 + pulse * 0.7),
                                  width: 2 + pulse * 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(pulse * 0.45),
                                    blurRadius: 18 + pulse * 22,
                                    spreadRadius: pulse * 7,
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
                          border: Border.all(color: accent.withOpacity(0.12), width: 1),
                        ),
                      ),

                      // ── Inner core + icon ─────────────────
                      Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xff05080d),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(online ? 0.35 : 0.12),
                              blurRadius: online ? 30 : 16,
                              spreadRadius: online ? 6 : -2,
                            ),
                          ],
                        ),
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

                // ── Status ───────────────────────────────────
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

                const SizedBox(height: 6),

                // anim ID badge
                Text(
                  _animId.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, letterSpacing: 2.5,
                    color: accent.withOpacity(0.35),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: disabled ? null : wakePC,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                          letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 13,
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

  // ── Which controllers does this animId use? ───────────────
  // Maps animId → set of controller tags it activates.
  // Used by build() to decide which layers to render.
  static const Map<String, List<String>> _animUses = {
    'comet':        ['spinA'],
    'fan_radar':    ['spinA', 'spinB', 'ripple'],
    'dashed_hb':    ['spinC', 'pulseB'],
    'ripple3':      ['ripple'],
    'dual_spin':    ['spinA', 'spinB'],
    'breathe':      ['pulseA'],
    'wave_spin':    ['wave', 'spinC'],
    'spin_fast':    ['spinA'],
    'heartbeat':    ['pulseB'],
    'radar_breathe':['ripple', 'pulseA'],
    'chaos':        ['spinA', 'spinB', 'spinC', 'ripple'],
    'wave':         ['wave'],
    'orbit':        ['spinC', 'ripple'],
    'pulse_burst':  ['pulseA', 'ripple'],
    'twin_fan':     ['spinA', 'spinC'],
    'sonar':        ['ripple', 'spinC'],
    'drift':        ['spinC'],
    'strobe':       ['pulseB', 'spinA'],
    'electric':     ['spinA', 'wave', 'pulseB'],
    'matrix':       ['wave', 'ripple'],
    'zen':          ['pulseA'],
    'vortex':       ['spinA', 'spinB', 'spinC'],
    'nova':         ['spinA', 'spinB', 'spinC', 'pulseA', 'pulseB', 'ripple', 'wave'],
  };

  bool _uses(String animId, String ctrl) =>
      (_animUses[animId] ?? []).contains(ctrl);

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

// ── Radar ring ────────────────────────────────────────────────
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
        final t       = ((ctrl.value + delay) % 1.0);
        final scale   = 0.3 + t * 0.7;
        final opacity = (1.0 - t) * 0.7;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(opacity), width: 2.0),
            ),
          ),
        );
      },
    );
  }
}

// ── Arc painter ───────────────────────────────────────────────
typedef _ArcDef = ({double startAngle, double sweepAngle});

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double opacity;
  final List<_ArcDef> arcs;
  _ArcPainter({required this.color, required this.strokeWidth,
               required this.opacity, required this.arcs});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color.withOpacity(opacity)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final arc in arcs) {
      canvas.drawArc(rect, arc.startAngle, arc.sweepAngle, false, paint);
    }
  }
  @override bool shouldRepaint(_ArcPainter old) => false;
}

// ── Dashed ring painter ───────────────────────────────────────
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  final double opacity;
  _DashedRingPainter({required this.color, required this.dashCount,
                      required this.strokeWidth, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color.withOpacity(opacity)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;
    final center     = Offset(size.width / 2, size.height / 2);
    final radius     = size.width / 2;
    final dashAngle  = (2 * pi) / dashCount;
    const gapFrac    = 0.4;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle, dashAngle * (1 - gapFrac), false, paint,
      );
    }
  }
  @override bool shouldRepaint(_DashedRingPainter old) => false;
}