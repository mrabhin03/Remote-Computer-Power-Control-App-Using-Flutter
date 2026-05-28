// Assets.dart
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:math';
import 'settings.dart';
import 'main.dart';

const String version   = "Version 3.01.0";
const Color bgColor    = Color(0xff020409);
const Color cardColor  = Color(0xff0a0f18);
const Color accentColor= Color(0xff4D8EFF);
const Color textAccent = Color(0xff88AAAA);

enum DrawerPage { home, settings }

Widget buildDrawer(
  BuildContext context, {
  DrawerPage current = DrawerPage.home,
  SysState? liveState,
}) {
  final state  = liveState ?? SysState.idle;
  final online = state == SysState.online;
  final booting= state == SysState.booting || state == SysState.loading;
  final error  = state == SysState.error;

  final Color dotColor = online  ? const Color(0xff44ff88)
                       : booting ? const Color(0xffffaa00)
                       : error   ? const Color(0xffff4d4d)
                                 : Colors.grey;

  final String stateLabel = online  ? "ONLINE"
                          : booting ? "CONNECTING"
                          : error   ? "NO SIGNAL"
                                    : "STANDBY";

  final IconData orbIcon = online  ? Icons.computer_rounded
                         : booting ? Icons.wifi_tethering_rounded
                         : error   ? Icons.signal_wifi_statusbar_connected_no_internet_4_rounded
                                   : Icons.power_settings_new_rounded;

  return Drawer(
    backgroundColor: bgColor,
    child: Stack(
      children: [

        // Same dot-grid as main card bg
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 28),

              // ── HEADER ──────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(8, 12, 18, 0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                  boxShadow: [
                    BoxShadow(color: accentColor.withOpacity(0.07), blurRadius: 40, spreadRadius: 4),
                    const BoxShadow(color: Colors.black87, blurRadius: 20),
                  ],
                ),
                child: Row(
                  children: [

                    // Orb — same style as main page orb
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff05080d),
                        border: Border.all(color: dotColor.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: dotColor.withOpacity(0.18), blurRadius: 16, spreadRadius: 1),
                        ],
                      ),
                      child: Center(
                        child: Icon(orbIcon, color: dotColor.withOpacity(0.85), size: 22,
                          shadows: [Shadow(color: dotColor.withOpacity(0.6), blurRadius: 8)],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "REMOTE SYSTEM INTERFACE",
                            style: TextStyle(
                              color: textAccent,
                              fontSize: 8,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "My PC",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotColor,
                                  boxShadow: [BoxShadow(color: dotColor, blurRadius: 5)],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                stateLabel,
                                style: TextStyle(
                                  color: dotColor.withOpacity(0.8),
                                  fontSize: 9,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section label ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      "NAVIGATION",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 9,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.05))),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Nav items ────────────────────────────────
              buildDrawerItem(
                icon: Icons.home_rounded,
                title: "HOME",
                subtitle: "Remote control dashboard",
                active: current == DrawerPage.home,
                onTap: () => Navigator.pushReplacement(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const FuturePCControl(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                )),
              ),

              buildDrawerItem(
                icon: Icons.settings_rounded,
                title: "SETTINGS",
                subtitle: "System configuration",
                active: current == DrawerPage.settings,
                onTap: () => Navigator.pushReplacement(context, PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                )),
              ),

              const Spacer(),

              // ── Footer ───────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(8, 12, 18, 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withOpacity(0.07),
                        border: Border.all(color: accentColor.withOpacity(0.12)),
                      ),
                      child: const Icon(Icons.memory_rounded, color: textAccent, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("SYSTEM BUILD",
                          style: TextStyle(color: Colors.grey[700], fontSize: 8, letterSpacing: 2.2)),
                        const SizedBox(height: 2),
                        Text(version,
                          style: TextStyle(color: Colors.grey[600], fontSize: 10, letterSpacing: 0.8,
                            fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "v3",
                      style: TextStyle(
                        color: accentColor.withOpacity(0.2),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Nav item ──────────────────────────────────────────────────
Widget buildDrawerItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  bool active = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        splashColor: accentColor.withOpacity(0.05),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: active
                ? accentColor.withOpacity(0.06)
                : const Color.fromRGBO(8, 12, 18, 0.85),
            border: Border.all(
              color: active
                  ? accentColor.withOpacity(0.22)
                  : Colors.white.withOpacity(0.04),
            ),
            boxShadow: active
                ? [BoxShadow(color: accentColor.withOpacity(0.08), blurRadius: 20)]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [

                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: active
                        ? accentColor.withOpacity(0.10)
                        : Colors.white.withOpacity(0.03),
                    border: Border.all(
                      color: active
                          ? accentColor.withOpacity(0.28)
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Icon(icon,
                    color: active ? accentColor : textAccent,
                    size: 18,
                    shadows: active
                        ? [Shadow(color: accentColor.withOpacity(0.6), blurRadius: 8)]
                        : [],
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: active ? Colors.white : Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active: glowing bar. Inactive: dim chevron.
                if (active)
                  Container(
                    width: 3, height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: accentColor,
                      boxShadow: [BoxShadow(color: accentColor, blurRadius: 8)],
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[800], size: 15),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void saveMACaddress(String mac, String link, String password) {
  http.get(Uri.parse("$link?password=$password&mac=$mac"));
}

// ── Dot grid — same as main page ─────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.022);
    for (double x = 0; x < size.width; x += 26) {
      for (double y = 0; y < size.height; y += 26) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }
  @override bool shouldRepaint(_DotGridPainter o) => false;
}