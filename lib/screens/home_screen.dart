import 'package:flutter/material.dart';
import 'package:river_watch/screens/add_reading_screen.dart';
import 'package:river_watch/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  dynamic _userStation; // Single station object
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStation();
  }

  Future<void> _loadUserStation() async {
    if (!mounted) return;

    try {
      final stations = await _api.getUserStations();
      print(stations);
      print('dsadsa');
      if (mounted) {
        setState(() {
          _userStation = stations.isNotEmpty ? stations.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading station: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Direct navigation - No checks
  void _goToAddReading(String timeOfDay) {
    if (_userStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Station not loaded yet. Please wait.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReadingScreen(
          timeOfDay: timeOfDay,
          station: _userStation, // Pass single station
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.indigo]),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, size: 80, color: Colors.white),
                  const Text("River Watch",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
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
                    const Text("River Watch",
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("Good Morning,",
                  style: TextStyle(fontSize: 24, color: Colors.white70)),
              const Text("River Handler",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Text("Select Time of Day",
                  style: TextStyle(fontSize: 18, color: Colors.white70)),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
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
    return GestureDetector(
      onTap: () => _goToAddReading(title),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)],
        ),
        child: Row(
          children: [
            const SizedBox(width: 30),
            Icon(icon, size: 70, color: color),
            const SizedBox(width: 30),
            Text(title,
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
