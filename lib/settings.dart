// settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Assets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final link1Controller = TextEditingController();
  final link2Controller = TextEditingController();
  final statusController = TextEditingController();
  final passwordController = TextEditingController();
  final MACaddressController = TextEditingController();

  bool _saved = false;
  bool _obscurePassword = true;

  static const _accent = Color(0xff4D8EFF);
  static const _cardBg = Color(0xff0a0f1a);
  static const _inputBg = Color(0xff0d1420);

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    link1Controller.text = prefs.getString("link1") ?? "";
    link2Controller.text = prefs.getString("link2") ?? "";
    MACaddressController.text = prefs.getString("MACaddress") ?? "";
    statusController.text = prefs.getString("sendvalue") ?? "";
    passwordController.text = prefs.getString("password") ?? "";
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("link1", link1Controller.text);
    await prefs.setString("link2", link2Controller.text);
    await prefs.setString("sendvalue", statusController.text);
    await prefs.setString("password", passwordController.text);
    await prefs.setString("MACaddress", MACaddressController.text);
    saveMACaddress(MACaddressController.text, link2Controller.text, passwordController.text);
    if (!mounted) return;

    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Color(0xff44ff88), size: 16),
            SizedBox(width: 10),
            Text("Settings saved", style: TextStyle(color: Colors.white70, letterSpacing: 1)),
          ],
        ),
        backgroundColor: const Color(0xff0f1a2e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xff44ff88).withOpacity(0.3), width: 1),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff020409),
      drawer: buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white38),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
            child: Column(
              children: [

                // ── Page header ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent,
                        boxShadow: [BoxShadow(color: _accent, blurRadius: 8)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "SYSTEM CONFIGURATION",
                      style: TextStyle(
                        fontSize: 11, letterSpacing: 2.5,
                        color: Color(0xff88AAAA), fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── NETWORK section ──────────────────────────
                _SectionCard(
                  label: "NETWORK",
                  icon: Icons.wifi_rounded,
                  accentColor: _accent,
                  children: [
                    _InputField(
                      controller: link1Controller,
                      hint: "Status URL",
                      helperText: "Endpoint to poll PC status",
                      icon: Icons.monitor_heart_outlined,
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: link2Controller,
                      hint: "Update / Wake URL",
                      helperText: "Endpoint to send wake signal",
                      icon: Icons.cloud_upload_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── DEVICE section ───────────────────────────
                _SectionCard(
                  label: "DEVICE",
                  icon: Icons.computer_rounded,
                  accentColor: _accent,
                  children: [
                    _InputField(
                      controller: MACaddressController,
                      hint: "MAC Address",
                      helperText: "e.g. AA:BB:CC:DD:EE:FF",
                      icon: Icons.device_hub_rounded,
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: statusController,
                      hint: "Boot Parameter",
                      helperText: "e.g. status=1",
                      icon: Icons.terminal_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── SECURITY section ─────────────────────────
                _SectionCard(
                  label: "SECURITY",
                  icon: Icons.shield_outlined,
                  accentColor: const Color(0xffFF9A4D),
                  children: [
                    _InputField(
                      controller: passwordController,
                      hint: "Password",
                      helperText: "API access password",
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[700],
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Save button ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _saved
                          ? [BoxShadow(
                              color: const Color(0xff44ff88).withOpacity(0.2),
                              blurRadius: 20, spreadRadius: 2,
                            )]
                          : [BoxShadow(
                              color: _accent.withOpacity(0.15),
                              blurRadius: 16, spreadRadius: 0,
                            )],
                    ),
                    child: ElevatedButton(
                      onPressed: saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: _saved
                            ? const Color(0xff0d1f14)
                            : const Color(0xff0f1828),
                        side: BorderSide(
                          color: _saved
                              ? const Color(0xff44ff88).withOpacity(0.45)
                              : _accent.withOpacity(0.30),
                          width: 1,
                        ),
                        elevation: 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _saved
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: ValueKey("saved"),
                                children: [
                                  Icon(Icons.check_rounded, size: 16,
                                      color: Color(0xff44ff88)),
                                  SizedBox(width: 8),
                                  Text(
                                    "SAVED",
                                    style: TextStyle(
                                      letterSpacing: 2, fontWeight: FontWeight.w700,
                                      fontSize: 13, color: Color(0xff44ff88),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                key: const ValueKey("save"),
                                children: [
                                  Icon(Icons.save_outlined,
                                      size: 16, color: _accent.withOpacity(0.8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "SAVE SETTINGS",
                                    style: TextStyle(
                                      letterSpacing: 2, fontWeight: FontWeight.w700,
                                      fontSize: 13, color: _accent.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Footer note ──────────────────────────────
                Text(
                  "Changes apply on next connection",
                  style: TextStyle(
                    fontSize: 10, letterSpacing: 1.2,
                    color: Colors.grey[800],
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final List<Widget> children;

  const _SectionCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(8, 12, 18, 0.93),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Section label row
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: accentColor.withOpacity(0.20), width: 1,
                  ),
                ),
                child: Icon(icon, size: 14, color: accentColor.withOpacity(0.8)),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, letterSpacing: 2.5,
                  color: accentColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                accentColor.withOpacity(0.15),
                Colors.transparent,
              ]),
            ),
          ),

          ...children,
        ],
      ),
    );
  }
}

// ── Input field ────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? helperText;
  final IconData? icon;
  final bool obscure;
  final Widget? suffixIcon;

  const _InputField({
    required this.controller,
    required this.hint,
    this.helperText,
    this.icon,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: Colors.white, fontSize: 13, letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey[700], size: 17)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xff0d1420),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.06), width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xff4D8EFF), width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText!,
              style: TextStyle(
                fontSize: 10, letterSpacing: 0.8,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ],
    );
  }
}