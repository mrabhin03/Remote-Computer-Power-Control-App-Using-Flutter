// Assets.dart
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'settings.dart';
import 'main.dart';

const String version = "Version 3.00.0";

const Color bgColor = Color(0xff020409);
const Color panelColor = Color(0xff0d1117);
const Color cardColor = Color(0xff161c26);
const Color borderColor = Color(0xff2a3545);
const Color accentColor = Color(0xff4D8EFF);
const Color textAccent = Color(0xff88AAAA);

Widget buildDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: bgColor,
    child: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.8),
          radius: 1.4,
          colors: [
            Color(0xff111927),
            Color(0xff020409),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [

            // ───────────────── HEADER ─────────────────
            const SizedBox(height: 32),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: panelColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.08),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  const BoxShadow(
                    color: Colors.black87,
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [

                  // ── Animated looking orb ──
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(0.35),
                          const Color(0xff05080d),
                        ],
                      ),
                      border: Border.all(
                        color: accentColor.withOpacity(0.25),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.computer_rounded,
                      color: textAccent,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── Title ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "REMOTE SYSTEM",
                          style: TextStyle(
                            color: textAccent,
                            fontSize: 10,
                            letterSpacing: 2.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "My PC",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xff44ff88),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "CONNECTED INTERFACE",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 9,
                                letterSpacing: 1.4,
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

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: Colors.white.withOpacity(0.06),
                thickness: 1,
              ),
            ),

            const SizedBox(height: 18),

            // ───────────────── NAVIGATION ─────────────────
            buildDrawerItem(
              icon: Icons.home_rounded,
              title: "HOME",
              subtitle: "Remote control dashboard",
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        const FuturePCControl(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),

            buildDrawerItem(
              icon: Icons.settings_rounded,
              title: "SETTINGS",
              subtitle: "System configuration",
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        const SettingsPage(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),

            const Spacer(),

            // ───────────────── FOOTER ─────────────────
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
              child: Row(
                children: [

                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.memory_rounded,
                      color: textAccent,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "SYSTEM BUILD",
                          style: TextStyle(
                            color: textAccent,
                            fontSize: 9,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          version,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w500,
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
      ),
    ),
  );
}

Widget buildDrawerItem({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 6,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: accentColor.withOpacity(0.08),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cardColor.withOpacity(0.9),
            border: Border.all(
              color: Colors.white.withOpacity(0.04),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.03),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            child: Row(
              children: [

                // ── Icon ──
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: accentColor.withOpacity(0.08),
                    border: Border.all(
                      color: accentColor.withOpacity(0.12),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: textAccent,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                // ── Text ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[700],
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void saveMACaddress(
  String mac,
  String link,
  String password,
) {
  http.get(
    Uri.parse(
      "${link}?password=${password}&mac=${mac}",
    ),
  );
}