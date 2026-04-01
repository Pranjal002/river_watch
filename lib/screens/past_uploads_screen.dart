import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:river_watch/screens/add_reading_screen.dart'; // ✅ new import
import 'package:river_watch/services/api_service.dart';

class PastUploadsScreen extends StatefulWidget {
  final String stationUserId;
  final dynamic station; // ✅ new: full station object

  const PastUploadsScreen({
    super.key,
    required this.stationUserId,
    required this.station, // ✅ new
  });

  @override
  State<PastUploadsScreen> createState() => _PastUploadsScreenState();
}

class _PastUploadsScreenState extends State<PastUploadsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _missingReadings = [];
  bool _isLoading = true;

  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B22);
  static const Color _cardBorder = Color(0xFF30363D);
  static const Color _textPrimary = Color(0xFFE6EDF3);
  static const Color _textSecondary = Color(0xFF8B949E);
  static const Color _amber = Color(0xFFD29922);
  static const Color _amberLight = Color(0xFFE3B341);

  @override
  void initState() {
    super.initState();
    _loadPendingUploads();
  }

  Future<void> _loadPendingUploads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _api.getPendingUploads(widget.stationUserId);
      final missingByDate = data['missingByDate'] as List? ?? [];

      final List<Map<String, dynamic>> flattened = [];
      for (var dateGroup in missingByDate) {
        final dateStr = dateGroup['date'] as String; // raw "2026-03-25"
        final missingSlots = dateGroup['missingSlots'] as List;

        for (var slot in missingSlots) {
          flattened.add({
            'date': dateStr, // ✅ keep raw date string for passing to screen
            'slot': slot['label'],
            'time': _getTimeForSlot(slot['label']),
            'emoji': _getEmojiForSlot(slot['label']),
          });
        }
      }

      // Sort by date (newest first)
      flattened.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        _missingReadings = flattened;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  String _getTimeForSlot(String slot) {
    switch (slot.toLowerCase()) {
      case 'morning':
        return "6:00 – 8:00 AM";
      case 'afternoon':
        return "12:00 – 2:00 PM";
      case 'evening':
        return "6:00 – 8:00 PM";
      default:
        return "";
    }
  }

  String _getEmojiForSlot(String slot) {
    switch (slot.toLowerCase()) {
      case 'morning':
        return "🌅";
      case 'afternoon':
        return "☀️";
      case 'evening':
        return "🌙";
      default:
        return "📊";
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          "Missing Readings",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _cardBorder, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2EA043)))
          : _missingReadings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EA043).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 50,
                          color: Color(0xFF3FB950),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "All readings submitted!",
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No missing readings found",
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _missingReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _missingReadings[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMissingCard(
                        rawDate: reading['date'], // ✅ "2026-03-25"
                        slot: reading['slot'],
                        time: reading['time'],
                        emoji: reading['emoji'],
                        onTap: () {
                          // ✅ Navigate to AddReadingScreen with card's date
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddReadingScreen(
                                timeOfDay: reading['slot'],
                                station: widget.station,
                                uploadDate: reading['date'], // ✅ raw date
                              ),
                            ),
                          ).then((_) =>
                              _loadPendingUploads()); // refresh on return
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMissingCard({
    required String rawDate, // ✅ raw "2026-03-25" used for navigation
    required String slot,
    required String time,
    required String emoji,
    required VoidCallback onTap, // ✅ new
  }) {
    return GestureDetector(
      onTap: onTap, // ✅ tappable
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _amber.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDate(rawDate), // ✅ formatted only for display
                    style: TextStyle(
                      color: _amberLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Missing",
                    style: TextStyle(
                      color: _amberLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Slot info row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.12),
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
                          style:
                              TextStyle(color: _textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                // ✅ Due badge with arrow hint
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Due",
                          style: TextStyle(
                              color: _amberLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          color: _amberLight, size: 10),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
