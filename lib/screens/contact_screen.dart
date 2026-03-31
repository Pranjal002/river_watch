import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // Dark theme colors (matching home screen)
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B22);
  static const Color _cardBorder = Color(0xFF30363D);
  static const Color _textPrimary = Color(0xFFE6EDF3);
  static const Color _textSecondary = Color(0xFF8B949E);
  static const Color _green = Color(0xFF2EA043);
  static const Color _greenLight = Color(0xFF3FB950);
  static const Color _red = Color(0xFFDA3633);

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
          "Contact Us",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _green.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 40,
                      color: Color(0xFF3FB950),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Innovative Engineering\nServices Pvt. Ltd.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Lalitpur 44600, Nepal",
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address card
            _buildContactCard(
              icon: Icons.location_on,
              iconColor: _greenLight,
              title: "Find us at the office",
              content: "Jwagal, Lalitpur, Nepal, 44600",
              onTap: () => _launchUrl(
                  'https://maps.google.com/?q=Innovative+Engineering+Services+Pvt+Ltd+Lalitpur+Nepal'),
              tapLabel: "Open in Maps",
            ),

            const SizedBox(height: 16),

            // Phone card
            _buildContactCard(
              icon: Icons.phone,
              iconColor: _greenLight,
              title: "Give us a ring",
              content:
                  "+977-1-5261776\n+977-1-5261774\n+977 9851198185\n\nSun–Fri, 09:30 AM – 05:30 PM",
              onTap: () => _launchUrl('tel:+97715261776'),
              tapLabel: "Call now",
            ),

            const SizedBox(height: 16),

            // Email card
            _buildContactCard(
              icon: Icons.email,
              iconColor: _greenLight,
              title: "Mail us at",
              content: "info@ies.com.np",
              onTap: () => _launchUrl('mailto:info@ies.com.np'),
              tapLabel: "Send email",
            ),

            const SizedBox(height: 16),

            // Rating badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFD29922), size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    "4.9",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "(25 reviews on Google)",
                    style: TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    required VoidCallback onTap,
    required String tapLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, color: _greenLight, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    tapLabel,
                    style: TextStyle(
                      color: _greenLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
