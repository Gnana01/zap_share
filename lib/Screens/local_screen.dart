import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:zap_share/Screens/device_detail_screen.dart'; // Adjust this import based on your project structure

class LocalScreen extends StatefulWidget {
  const LocalScreen({super.key});

  @override
  State<LocalScreen> createState() => _LocalScreenState();
}

class _LocalScreenState extends State<LocalScreen> with SingleTickerProviderStateMixin {
  final _flutterP2pConnectionPlugin = FlutterP2pConnection();
  List<DiscoveredPeers> peers = [];
  WifiP2PInfo? wifiP2PInfo;
  bool isConnected = false;
  bool isConnecting = false; // Controls overlay visibility
  bool isSearching = false; // Track if the app is currently searching
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _flutterP2pConnectionPlugin.disconnect();
    _init();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _rippleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    );

    _flutterP2pConnectionPlugin.streamWifiP2PInfo().listen((event) {
      setState(() {
        wifiP2PInfo = event;
        isConnected = wifiP2PInfo?.isConnected ?? false;
      });

      _handleConnectionChange();
    });
  }

  void _handleConnectionChange() {
    if (isConnected) {
      _scanTimer?.cancel();
      setState(() => isConnecting = false); // Hide overlay when connected
    } else {
      _scanTimer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted) _startScanning();
      });
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _flutterP2pConnectionPlugin.unregister();
    _rippleController.dispose();
    super.dispose();
  }

  void _init() async {
    await _flutterP2pConnectionPlugin.initialize();
    await _flutterP2pConnectionPlugin.register();
    _flutterP2pConnectionPlugin.streamPeers().listen((event) {
      setState(() {
        peers = event;
      });
    });
  }

  void _startScanning() async {
    await _flutterP2pConnectionPlugin.discover();
  }

  void _startSearch() async {
    setState(() => isSearching = true); // Start searching
    _rippleController.repeat(reverse: true); // Start ripple animation

    await _flutterP2pConnectionPlugin.discover();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => isSearching = false); // Stop searching
        _rippleController.stop(); // Stop ripple animation
      }
    });
  }

  void _connectToDevice(int index) async {
    if (isConnected || isConnecting) return;

    setState(() => isConnecting = true); // Show overlay

    bool success = await _flutterP2pConnectionPlugin.connect(peers[index].deviceAddress);

    if (success) {
      setState(() {
        isConnected = true;
        isConnecting = false; // Hide overlay
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDetailScreen(
            deviceName: peers[index].deviceName,
            deviceAddress: peers[index].deviceAddress,
            p2pPlugin: _flutterP2pConnectionPlugin,
          ),
        ),
      );
    } else {
      setState(() => isConnecting = false); // Hide overlay on failure
      _showError("Failed to connect. Please try again.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double hotspotX = screenWidth / 2;
    double hotspotY = screenHeight * 0.35;
    double baseRadius = 120;
    double radius = baseRadius + (peers.length * 10);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Local",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.black),
          ),
          if (isSearching)
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _rippleAnimation.value,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          GestureDetector(
            onTap: _startSearch, // Trigger search on tap
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSearching ? Colors.white : Colors.white,
              ),
              child: Icon(
                Icons.phone_android_outlined,
                size: 60,
                color: isSearching ? Colors.black : Colors.black,
              ),
            ),
          ),
          ...List.generate(peers.length, (index) {
            double angle = (index / peers.length) * 2 * pi;
            double x = hotspotX + radius * cos(angle);
            double y = hotspotY + radius * sin(angle);

            return Positioned(
              left: x - 30,
              top: y - 30,
              child: GestureDetector(
                onTap: () => _connectToDevice(index),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    peers[index].deviceName.toString().characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          if (isConnecting)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link, size: 60, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "Connecting...",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}