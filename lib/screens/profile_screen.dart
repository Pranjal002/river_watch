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
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white70, size: 60),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Failed to load profile:\n$_errorMessage",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 16),
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
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Retry"),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _stationData == null
                            ? const Center(
                                child: Text(
                                  "No profile data found.",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 16),
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
                                        color: Colors.white.withOpacity(0.15),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.4),
                                            width: 3),
                                      ),
                                      child: const Icon(Icons.person,
                                          size: 80, color: Colors.white),
                                    ),
                                    const SizedBox(height: 16),

                                    // Full Name
                                    Text(
                                      _stationData!['fullName'] ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "@${_stationData!['userName'] ?? 'N/A'}",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white70),
                                    ),

                                    const SizedBox(height: 32),

                                    // Info Cards
                                    _buildInfoCard(
                                      icon: Icons.badge,
                                      label: "Station User ID",
                                      value: _stationData!['stationUserId']
                                              ?.toString() ??
                                          'N/A',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.location_on,
                                      label: "Station Name",
                                      value:
                                          _stationData!['stationName'] ?? 'N/A',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.confirmation_number,
                                      label: "Station ID",
                                      value: _stationData!['stationId']
                                              ?.toString() ??
                                          'N/A',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.water,
                                      label: "River Name",
                                      value:
                                          _stationData!['riverName'] ?? 'N/A',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoCard(
                                      icon: Icons.tag,
                                      label: "River ID",
                                      value: _stationData!['riverId']
                                              ?.toString() ??
                                          'N/A',
                                    ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
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
