// Assets.dart

import 'package:flutter/material.dart';
import 'settings.dart';
import 'main.dart';

Widget buildDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: const Color(0xff141a23), 
    child: SafeArea(
      child: Column(
        children: [

          const SizedBox(height: 30),

          buildDrawerItem(
            icon: Icons.home_rounded,
            title: "Home",
            onTap: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const FuturePCControl(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
          ),

          buildDrawerItem(
            icon: Icons.settings_rounded,
            title: "Settings",
            onTap: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const SettingsPage(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "Version 1.3.0",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildDrawerItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xff1c2430), 
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}