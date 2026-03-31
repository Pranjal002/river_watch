import 'package:flutter/material.dart';
import 'package:river_watch/screens/add_reading_screen.dart';
import 'package:river_watch/screens/profile_screen.dart';
import 'package:river_watch/screens/contact_screen.dart';
import 'package:river_watch/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();

  dynamic _userStation;
  Map<String, dynamic> _readingStatus = {};
  bool _isLoading = true;
  String _todayDate = "";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Load Station
      final stations = await _api.getUserStations();
      if (stations.isNotEmpty) {
        _userStation = stations.first;
      }

      // Load Reading Status (if station exists)
      if (_userStation != null) {
        final status = await _api.getReadingTimeStatus(
          _userStation['stationUserId'].toString(),
        );
        _readingStatus = status;
        _todayDate = status['today'] ?? "";
      }
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Check if a time slot is still missing
  bool _isSlotMissing(String timeOfDay) {
    final key = "is${timeOfDay}Missing";
    return _readingStatus[key] ?? true; // default to true (allow) if not found
  }

  void _goToAddReading(String timeOfDay) {
    if (_userStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Station not loaded yet. Please wait.")),
      );
      return;
    }

    if (!_isSlotMissing(timeOfDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You have already submitted $timeOfDay reading today."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReadingScreen(
          timeOfDay: timeOfDay,
          station: _userStation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "River Watch",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_phone),
              title: const Text("Contact"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ContactScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () => _api.logout().then(
                  (_) => Navigator.pushReplacementNamed(context, '/login')),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu,
                            color: Colors.white, size: 30),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Text(
                      "River Watch",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const Text("Good Morning,",
                  style: TextStyle(fontSize: 24, color: Colors.white70)),
              const Text("River Handler",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),

              if (_todayDate.isNotEmpty)
                Text("Today: $_todayDate",
                    style:
                        const TextStyle(fontSize: 16, color: Colors.white70)),

              const SizedBox(height: 10),
              const Text("Select Time of Day",
                  style: TextStyle(fontSize: 18, color: Colors.white70)),

              const SizedBox(height: 20),

              // Time Cards
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTimeCard(
                                "Morning", Icons.wb_sunny, Colors.orange),
                            const SizedBox(height: 20),
                            _buildTimeCard(
                                "Evening", Icons.wb_twilight, Colors.purple),
                            const SizedBox(height: 20),
                            _buildTimeCard(
                                "Night", Icons.nightlight_round, Colors.indigo),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(String title, IconData icon, Color color) {
    final isMissing = _isSlotMissing(title);
    final isEnabled = isMissing;

    return GestureDetector(
      onTap: isEnabled ? () => _goToAddReading(title) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.65,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.35), blurRadius: 20)
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 30),
              Icon(icon, size: 70, color: color),
              const SizedBox(width: 30),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  if (!isEnabled)
                    const Text(
                      "Already Submitted",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
