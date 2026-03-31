import 'package:flutter/material.dart';
import 'package:river_watch/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _stationData;
  bool _isLoading = true;
  String? _errorMessage;

  // Dark theme colors (matching home screen)
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B22);
  static const Color _cardBorder = Color(0xFF30363D);
  static const Color _textPrimary = Color(0xFFE6EDF3);
  static const Color _textSecondary = Color(0xFF8B949E);
  static const Color _green = Color(0xFF2EA043);
  static const Color _greenLight = Color(0xFF3FB950);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final stations = await _api.getUserStations();
      if (mounted) {
        setState(() {
          _stationData = stations.isNotEmpty ? stations.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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
          "Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _cardBorder, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2EA043)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: _textSecondary, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load profile:\n$_errorMessage",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : _stationData == null
                  ? Center(
                      child: Text(
                        "No profile data found.",
                        style: TextStyle(color: _textSecondary, fontSize: 16),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _green.withOpacity(0.15),
                              border: Border.all(
                                  color: _green.withOpacity(0.4), width: 3),
                            ),
                            child: Icon(Icons.person,
                                size: 80, color: _greenLight),
                          ),
                          const SizedBox(height: 16),

                          // Full Name
                          Text(
                            _stationData!['fullName'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@${_stationData!['userName'] ?? 'N/A'}",
                            style:
                                TextStyle(fontSize: 16, color: _textSecondary),
                          ),

                          const SizedBox(height: 32),

                          // Info Cards
                          _buildInfoCard(
                            icon: Icons.badge,
                            label: "Station User ID",
                            value: _stationData!['stationUserId']?.toString() ??
                                'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.location_on,
                            label: "Station Name",
                            value: _stationData!['stationName'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.confirmation_number,
                            label: "Station ID",
                            value:
                                _stationData!['stationId']?.toString() ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.water,
                            label: "River Name",
                            value: _stationData!['riverName'] ?? 'N/A',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.tag,
                            label: "River ID",
                            value:
                                _stationData!['riverId']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Icon(icon, color: _greenLight, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
