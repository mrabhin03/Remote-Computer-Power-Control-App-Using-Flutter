// main.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Assets.dart';
import 'package:shared_preferences/shared_preferences.dart';

String statusLink="",updateLink="",password="",sendvalue="",ipaddress="";

Future<void> loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    statusLink = prefs.getString("link1") ?? "";
    updateLink = prefs.getString("link2") ?? "";
    ipaddress = prefs.getString("ipaddress") ?? "";
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

class _FuturePCControlState extends State<FuturePCControl>
    with SingleTickerProviderStateMixin {
  String mode = "idle"; // idle | boot | online
  String statusText = "LOADING...";
  Color accent = const Color(0xffFF4D4D);

  late AnimationController _controller;
  Timer? _pollingTimer;
  @override
  @override

  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    loadExisting();
    pollStatus(); // first load immediately

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) => pollStatus(),
    );
  }
  int i=0;
@override
void dispose() {
  _pollingTimer?.cancel();
  _controller.dispose(); // VERY IMPORTANT
  super.dispose();
}
 Future<void> pollStatus() async {
  try {
    final res = await http.get(
      Uri.parse(
        "${statusLink}?password=${password}&ipaddress=${ipaddress}",
      ),
    );

    if (!mounted) return; 

    final data = jsonDecode(res.body);

    setState(() {
      mode = data["mode"];
      statusText = data["text"];
      accent = Color(
        int.parse(data["color"].replaceAll("#", "0xff")),
      );
    });
  } catch (_) {
    setState(() {
      if(i>=1){
        statusText = "Something Wrong";
      }
      accent = const Color(0xffFF4D4D);
    });
  }
  i++;
}

  void wakePC() async {
    setState(() {
      mode = "boot";
      statusText = "TRANSMITTING...";
      accent = Colors.orange;
    });
    await http.get(
      Uri.parse(
        "${updateLink}?password=${password}&ipaddress=${ipaddress}&${sendvalue}",
      ),
    );
    
    pollStatus();
  }

  @override
Widget build(BuildContext context) {
  bool spinning = mode == "boot";
  bool disabled = mode == "boot" || mode == "online";

  return Scaffold(
    backgroundColor: const Color(0xff020409),
    drawer: buildDrawer(context),

    // 👇 Transparent AppBar so drawer icon appears
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
                "REMOTE SYSTEM INTERFACE",
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: Color(0xff88AAAA),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: 180,
                height: 180,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: spinning ? _controller.value * 2 * pi : 0,
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [accent, accent]),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(
                            mode == "online" ? 0.9 : 0.4,
                          ),
                          blurRadius: 35,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff05080d),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                statusText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  shadows: [Shadow(color: accent, blurRadius: 10)],
                ),
              ),

              const SizedBox(height: 28),

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
                        ? Colors.grey[800]
                        : const Color(0xff1a1f27),
                  ),
                  child: Text(
                    disabled ? "SYSTEM ACTIVE" : "POWER ON",
                    style: const TextStyle(
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Live status · Auto sync",
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.grey,
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
