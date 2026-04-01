import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:river_watch/screens/add_reading_screen.dart';
import 'package:river_watch/screens/profile_screen.dart';
import 'package:river_watch/screens/contact_screen.dart';
import 'package:river_watch/services/api_service.dart';
import 'package:river_watch/screens/past_uploads_screen.dart';

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

  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B22);
  static const Color _cardBorder = Color(0xFF30363D);
  static const Color _textPrimary = Color(0xFFE6EDF3);
  static const Color _textSecondary = Color(0xFF8B949E);
  static const Color _green = Color(0xFF2EA043);
  static const Color _greenLight = Color(0xFF3FB950);
  static const Color _amber = Color(0xFFD29922);
  static const Color _amberLight = Color(0xFFE3B341);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final stations = await _api.getUserStations();
      if (stations.isNotEmpty) {
        _userStation = stations.first;
      }
      if (_userStation != null) {
        final status = await _api.getReadingTimeStatus(
          _userStation['stationUserId'].toString(),
        );
        _readingStatus = status;
      }
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getSlotStatus(String slot) {
    final key = 'is${slot}Missing';
    final isMissing = _readingStatus[key];
    if (isMissing == null) return 'upcoming';
    return isMissing ? 'due' : 'done';
  }

  String get _todayFormatted {
    final today = _readingStatus['today'];
    if (today == null) {
      return DateFormat('EEE, d MMMM yyyy').format(DateTime.now());
    }
    try {
      return DateFormat('EEE, d MMMM yyyy').format(DateTime.parse(today));
    } catch (_) {
      return today.toString();
    }
  }

  // ✅ Returns raw "yyyy-MM-dd" string from API for sending to backend
  String get _todayRaw {
    return _readingStatus['today'] ??
        DateTime.now().toIso8601String().substring(0, 10);
  }

  void _goToAddReading(String timeOfDay) {
    if (_userStation == null) {
      _showSnack("Station not loaded yet. Please wait.");
      return;
    }
    if (_getSlotStatus(timeOfDay) == 'done') {
      _showSnack("$timeOfDay reading already submitted today.",
          isWarning: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReadingScreen(
          timeOfDay: timeOfDay,
          station: _userStation,
          uploadDate: _todayRaw, // ✅ pass API date e.g. "2026-03-31"
        ),
      ),
    ).then((_) => _loadAllData());
  }

  void _showSnack(String msg, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isWarning ? _amber : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _userStation?['fullName'] ?? 'River Handler';
    final stationName = _userStation?['stationName'] ?? '';

    return Scaffold(
      backgroundColor: _bg,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 24),
            _buildGreeting(fullName, stationName),
            const SizedBox(height: 20),
            _buildDateCard(),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "TODAY'S READINGS",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2EA043)))
                  : _buildReadingCards(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Icon(Icons.menu, color: _textPrimary, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "RiverWatch Nepal",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _greenLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _greenLight.withOpacity(0.5), blurRadius: 6)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String fullName, String stationName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Good morning,",
              style: TextStyle(color: _textSecondary, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            fullName,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (stationName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3FB950),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    "$stationName · Active",
                    style: TextStyle(
                      color: _greenLight,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Text(
              "TODAY",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Text(
              _todayFormatted,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCards() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildSlotCard(slot: "Morning", time: "6:00 – 8:00 AM", emoji: "🌅"),
          const SizedBox(height: 12),
          _buildSlotCard(
              slot: "Afternoon", time: "12:00 – 2:00 PM", emoji: "☀️"),
          const SizedBox(height: 12),
          _buildSlotCard(slot: "Evening", time: "6:00 – 8:00 PM", emoji: "🌙"),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSlotCard(
      {required String slot, required String time, required String emoji}) {
    final status = _getSlotStatus(slot);
    final isDone = status == 'done';
    final isDue = status == 'due';

    return GestureDetector(
      onTap: () => _goToAddReading(slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDue
                ? _amber.withOpacity(0.5)
                : isDone
                    ? _green.withOpacity(0.3)
                    : _cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDone
                    ? _green.withOpacity(0.12)
                    : isDue
                        ? _amber.withOpacity(0.12)
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slot,
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(time,
                      style: TextStyle(color: _textSecondary, fontSize: 13)),
                ],
              ),
            ),
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'done') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: _greenLight, size: 14),
            const SizedBox(width: 4),
            Text("Done",
                style: TextStyle(
                    color: _greenLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
    } else if (status == 'due') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _amber.withOpacity(0.4)),
        ),
        child: Text("Due now",
            style: TextStyle(
                color: _amberLight, fontSize: 13, fontWeight: FontWeight.w700)),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Text("Upcoming",
            style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _card,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: _bg,
              border: Border(bottom: BorderSide(color: _cardBorder)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.water_drop,
                      size: 30, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text("RiverWatch Nepal",
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                Text("River Monitoring System",
                    style: TextStyle(color: _textSecondary, fontSize: 12)),
              ],
            ),
          ),
          _drawerTile(
              Icons.home_outlined, "Home", () => Navigator.pop(context)),
          _drawerTile(Icons.history, "Past Uploads", () {
            Navigator.pop(context);
            if (_userStation != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PastUploadsScreen(
                    stationUserId: _userStation['stationUserId'].toString(),
                    station: _userStation, // ✅ pass full station object
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Station not loaded yet")),
              );
            }
          }),
          _drawerTile(Icons.person_outline, "Profile", () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _drawerTile(Icons.contact_phone_outlined, "Contact", () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ContactScreen()));
          }),
          Divider(color: _cardBorder, thickness: 1),
          _drawerTile(Icons.logout, "Logout", () {
            _api
                .logout()
                .then((_) => Navigator.pushReplacementNamed(context, '/login'));
          }, color: Colors.red.shade400),
        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? _textSecondary, size: 22),
      title: Text(title,
          style: TextStyle(
              color: color ?? _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}
