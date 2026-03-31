import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:river_watch/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class AddReadingScreen extends StatefulWidget {
  final String timeOfDay;
  final dynamic station;

  const AddReadingScreen({
    super.key,
    required this.timeOfDay,
    required this.station,
  });

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final ApiService _api = ApiService();

  File? _selectedImage;
  final _gaugeController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;

  // Dark theme colors (matching home screen)
  static const Color _bg = Color(0xFF0D1117);
  static const Color _card = Color(0xFF161B22);
  static const Color _cardBorder = Color(0xFF30363D);
  static const Color _textPrimary = Color(0xFFE6EDF3);
  static const Color _textSecondary = Color(0xFF8B949E);
  static const Color _green = Color(0xFF2EA043);
  static const Color _fieldColor = Color(0xFF1C2128);

  /// Morning = 1, Afternoon = 2, Evening = 3
  int get _readingTime {
    switch (widget.timeOfDay.toLowerCase()) {
      case 'morning':
        return 1;
      case 'afternoon':
        return 2;
      case 'evening':
        return 3;
      default:
        return 1;
    }
  }

  // Replace your existing _convertToPng function with this one
  Future<File?> _convertToPng(File imageFile) async {
    try {
      print("🔄 Converting image to PNG: ${imageFile.path}");

      // Get file statistics (including modified time)
      final fileStat = await imageFile.stat();

      // Use modified time (for camera photos, this is usually the capture time)
      final captureTime = fileStat.modified;

      // Format timestamp: YYYYMMDD_HHMMSS (e.g., 20260331_195809)
      final formattedTime = _formatTimestamp(captureTime);

      // Read the image file
      final bytes = await imageFile.readAsBytes();

      // Decode the image
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        print("❌ Failed to decode image");
        return null;
      }

      // Create a temporary directory for the converted image
      final tempDir = await getTemporaryDirectory();
      final pngFile = File('${tempDir.path}/converted_${formattedTime}.png');

      // Encode as PNG and save
      final pngBytes = img.encodePng(image);
      await pngFile.writeAsBytes(pngBytes);

      print(
          "✅ Image converted to PNG: ${pngFile.path}, Size: ${await pngFile.length()} bytes");
      return pngFile;
    } catch (e) {
      print("❌ Error converting image to PNG: $e");
      return null;
    }
  }

// Add this helper function right after _convertToPng
  String _formatTimestamp(DateTime timestamp) {
    // Format: YYYYMMDD_HHMMSS
    return '${timestamp.year}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}'
        '_'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (picked != null) {
        final originalFile = File(picked.path);
        print("📸 Original image: ${originalFile.path}");
        print("📸 Original size: ${await originalFile.length()} bytes");

        // Convert to PNG if needed
        File? pngFile = await _convertToPng(originalFile);

        if (pngFile != null) {
          setState(() => _selectedImage = pngFile);
        } else {
          // If conversion fails, try using original file
          setState(() => _selectedImage = originalFile);
          print("⚠️ Using original file (conversion failed)");
        }
      }
    } catch (e) {
      print("❌ Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking image: ${e.toString()}"),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _submitReading() async {
    if (_gaugeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter gauge value")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _api.submitGaugeReading(
        stationUserId: widget.station['stationUserId'].toString(),
        gaugeReading: double.parse(_gaugeController.text.trim()),
        readingTime: _readingTime,
        remarks: _remarksController.text.trim(),
        imageFile: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Reading submitted successfully!"),
            backgroundColor: Color(0xFF2EA043),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: $e"), backgroundColor: Colors.red.shade800),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: Text(
          "${widget.timeOfDay} Reading",
          style: TextStyle(
              color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _cardBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on,
                        size: 28, color: Color(0xFF3FB950)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.station['stationName'] ?? "Station",
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary),
                        ),
                        Text(
                          "River: ${widget.station['riverName'] ?? 'N/A'}",
                          style: TextStyle(color: _textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildLabel("Gauge Value (meters)"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _gaugeController,
              hint: "e.g. 3.45",
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 20),

            _buildLabel("Remarks"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _remarksController,
              hint: "Any observations...",
              maxLines: 4,
            ),

            const SizedBox(height: 28),

            _buildLabel("Photo Evidence"),
            const SizedBox(height: 12),

            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorder),
              ),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 48, color: _textSecondary),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _photoButton(Icons.camera_alt, "Camera",
                                () => _pickImage(ImageSource.camera)),
                            const SizedBox(width: 12),
                            _photoButton(Icons.photo_library, "Gallery",
                                () => _pickImage(ImageSource.gallery)),
                          ],
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withOpacity(0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text("Submit Reading",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
          color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: _textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cursorColor: const Color(0xFF3FB950),
      ),
    );
  }

  Widget _photoButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _green.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3FB950), size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
