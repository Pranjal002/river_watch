import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:river_watch/models/river_reading.dart';
import 'package:river_watch/services/api_service.dart';

class StationScreen extends StatefulWidget {
  final dynamic station; // This will be a Map from your .NET API

  const StationScreen({super.key, required this.station});

  @override
  State<StationScreen> createState() => _StationScreenState();
}

class _StationScreenState extends State<StationScreen> {
  final ApiService _api = ApiService();

  File? _selectedImage;
  final _gaugeController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedTimeOfDay = 'Morning';

  final List<String> _timeSlots = ['Morning', 'Evening', 'Night'];

  // Pick image from camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Submit reading to API
  Future<void> _submitReading() async {
    if (_gaugeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter gauge value')),
      );
      return;
    }

    try {
      String photoUrl = '';

      // Upload photo if selected
      if (_selectedImage != null) {
        photoUrl = await _api.uploadPhoto(
          _selectedImage!,
          widget.station['id'].toString(),
        );
      }

      final readingData = {
        "timeOfDay": _selectedTimeOfDay,
        "gaugeValue": double.parse(_gaugeController.text.trim()),
        "photoUrl": photoUrl,
        "remarks": _remarksController.text.trim(),
        "date": DateTime.now().toIso8601String(),
      };

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reading submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        setState(() {
          _selectedImage = null;
          _gaugeController.clear();
          _remarksController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station['name'] ?? 'River Station'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 40, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.station['name'] ?? 'Station',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.station['location'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // === ADD NEW READING SECTION ===
            const Text(
              "Add New Reading",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Time of Day
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTimeOfDay,
                      decoration: const InputDecoration(
                        labelText: "Time of Day",
                        border: OutlineInputBorder(),
                      ),
                      items: _timeSlots.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTimeOfDay = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Gauge Value
                    TextField(
                      controller: _gaugeController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Gauge Value (meters)",
                        border: OutlineInputBorder(),
                        suffixText: "m",
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Remarks
                    TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Remarks / Observations",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Photo Section
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImage == null
                          ? Center(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text("Take Photo"),
                              ),
                            )
                          : Stack(
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() => _selectedImage = null);
                                    },
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitReading,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text("Submit Reading"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // === PREVIOUS READINGS SECTION ===
            const Text(
              "Previous Readings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<dynamic>>(
              future: _api.getReadings(widget.station['id'].toString()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No previous readings found",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final readings = snapshot.data!
                    .map((json) => RiverReading.fromJson(json))
                    .toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: readings.length,
                  itemBuilder: (context, index) {
                    final reading = readings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.water_drop,
                            color: Colors.blue, size: 40),
                        title: Text(
                          "${reading.timeOfDay} • ${reading.formattedDate}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Gauge: ${reading.gaugeValue} meters"),
                            if (reading.remarks.isNotEmpty)
                              Text("Remarks: ${reading.remarks}"),
                          ],
                        ),
                        trailing: reading.photoUrl.isNotEmpty
                            ? const Icon(Icons.photo, color: Colors.green)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
