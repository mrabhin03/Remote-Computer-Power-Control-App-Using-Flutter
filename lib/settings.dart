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

  @override
  void initState() {
    super.initState();
    loadExisting();
  }

  Future<void> loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    link1Controller.text = prefs.getString("link1") ?? "";
    link2Controller.text = prefs.getString("link2") ?? "";
    statusController.text = prefs.getString("sendvalue") ?? "";
    passwordController.text = prefs.getString("password") ?? "";
  }

  Future<void> saveSettings() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString("link1", link1Controller.text);
  await prefs.setString("link2", link2Controller.text);
  await prefs.setString("sendvalue", statusController.text);
  await prefs.setString("password", passwordController.text);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Settings Saved")),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      extendBodyBehindAppBar: true,

      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xff101820), Color(0xff020409)],
          ),
        ),
        child: Center(
          child: Container(
            width: 360,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(10, 14, 20, 0.85),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "SYSTEM SETTINGS",
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Color(0xff88AAAA),
                  ),
                ),

                const SizedBox(height: 24),

                buildInputField(link1Controller, "Status URL"),
                const SizedBox(height: 16),

                buildInputField(link2Controller, "Update URL"),
                const SizedBox(height: 16),

                buildInputField(statusController, "Boot status(Enter status=1)"),
                const SizedBox(height: 16),

                buildInputField(passwordController, "Password", obscure: true),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: const Color(0xff1a1f27),
                    ),
                    child: const Text(
                      "SAVE SETTINGS",
                      style: TextStyle(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xff1c2430),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}