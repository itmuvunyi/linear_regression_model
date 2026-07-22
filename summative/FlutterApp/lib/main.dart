import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SolarPowerApp());
}

class SolarPowerApp extends StatelessWidget {
  const SolarPowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Power Prediction System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E1E),
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // API Base URL controller (Defaults to Android Emulator or localhost)
  final TextEditingController _apiUrlController =
      TextEditingController(text: 'http://127.0.0.1:8000');

  // Input Controllers with realistic sample defaults
  final TextEditingController _tempController = TextEditingController(text: '22.5');
  final TextEditingController _humidityController = TextEditingController(text: '35.0');
  final TextEditingController _pressureController = TextEditingController(text: '1018.5');
  final TextEditingController _cloudCoverController = TextEditingController(text: '12.0');
  final TextEditingController _radiationController = TextEditingController(text: '480.0');
  final TextEditingController _windSpeedController = TextEditingController(text: '8.5');
  final TextEditingController _windDirController = TextEditingController(text: '195.0');
  final TextEditingController _aoiController = TextEditingController(text: '32.0');
  final TextEditingController _zenithController = TextEditingController(text: '42.5');
  final TextEditingController _azimuthController = TextEditingController(text: '168.0');

  bool _isLoading = false;
  double? _predictedPower;
  String? _errorMessage;

  @override
  void dispose() {
    _apiUrlController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _pressureController.dispose();
    _cloudCoverController.dispose();
    _radiationController.dispose();
    _windSpeedController.dispose();
    _windDirController.dispose();
    _aoiController.dispose();
    _zenithController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  Future<void> _submitPrediction() async {
    setState(() {
      _errorMessage = null;
      _predictedPower = null;
    });

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct validation errors in the form.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final baseUrl = _apiUrlController.text.trim().replaceAll(RegExp(r'/$'), '');
    final predictEndpoint = Uri.parse('$baseUrl/predict');

    final payload = {
      'temperature_2_m_above_gnd': double.parse(_tempController.text),
      'relative_humidity_2_m_above_gnd': double.parse(_humidityController.text),
      'mean_sea_level_pressure_MSL': double.parse(_pressureController.text),
      'total_cloud_cover_sfc': double.parse(_cloudCoverController.text),
      'shortwave_radiation_backwards_sfc': double.parse(_radiationController.text),
      'wind_speed_10_m_above_gnd': double.parse(_windSpeedController.text),
      'wind_direction_10_m_above_gnd': double.parse(_windDirController.text),
      'angle_of_incidence': double.parse(_aoiController.text),
      'zenith': double.parse(_zenithController.text),
      'azimuth': double.parse(_azimuthController.text),
    };

    try {
      final response = await http.post(
        predictEndpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictedPower = (data['predicted_solar_power'] as num).toDouble();
        });
      } else {
        final errData = jsonDecode(response.body);
        setState(() {
          _errorMessage = 'API Error (${response.statusCode}): ${errData['detail'] ?? response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network connection failure: $e\nEnsure API server is running at $baseUrl';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String unit,
    required double minVal,
    required double maxVal,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: unit,
          prefixIcon: Icon(icon, color: const Color(0xFFFF9800)),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required.';
          }
          final numVal = double.tryParse(value.trim());
          if (numVal == null) {
            return 'Enter a valid numeric number.';
          }
          if (numVal < minVal || numVal > maxVal) {
            return 'Value must be between $minVal and $maxVal $unit.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Solar Power Prediction System',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 2,
        leading: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFF9800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: const Column(
                  children: [
                    Icon(Icons.solar_power_rounded, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'AI Solar Energy Optimizer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Predict real-time solar farm power generation using environmental telemetry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // API Endpoint Configuration Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextFormField(
                    controller: _apiUrlController,
                    decoration: const InputDecoration(
                      labelText: 'FastAPI Service Base URL',
                      hintText: 'http://127.0.0.1:8000',
                      prefixIcon: Icon(Icons.dns_rounded, color: Colors.amber),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'API URL is required' : null,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Section 1: Meteorological Parameters
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Meteorological Conditions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D)),
                ),
              ),

              _buildTextField(
                controller: _tempController,
                label: 'Temperature at 2m',
                hint: 'e.g. 22.5',
                unit: '°C',
                minVal: -30.0,
                maxVal: 60.0,
                icon: Icons.thermostat_rounded,
              ),

              _buildTextField(
                controller: _humidityController,
                label: 'Relative Humidity',
                hint: 'e.g. 35.0',
                unit: '%',
                minVal: 0.0,
                maxVal: 100.0,
                icon: Icons.water_drop_rounded,
              ),

              _buildTextField(
                controller: _pressureController,
                label: 'Mean Sea Level Pressure',
                hint: 'e.g. 1018.5',
                unit: 'hPa',
                minVal: 850.0,
                maxVal: 1100.0,
                icon: Icons.compress_rounded,
              ),

              _buildTextField(
                controller: _cloudCoverController,
                label: 'Total Cloud Cover',
                hint: 'e.g. 12.0',
                unit: '%',
                minVal: 0.0,
                maxVal: 100.0,
                icon: Icons.cloud_rounded,
              ),

              _buildTextField(
                controller: _radiationController,
                label: 'Shortwave Radiation Backwards',
                hint: 'e.g. 480.0',
                unit: 'W/m²',
                minVal: 0.0,
                maxVal: 1200.0,
                icon: Icons.wb_sunny_outlined,
              ),

              _buildTextField(
                controller: _windSpeedController,
                label: 'Wind Speed at 10m',
                hint: 'e.g. 8.5',
                unit: 'm/s',
                minVal: 0.0,
                maxVal: 150.0,
                icon: Icons.air_rounded,
              ),

              _buildTextField(
                controller: _windDirController,
                label: 'Wind Direction at 10m',
                hint: 'e.g. 195.0',
                unit: '°',
                minVal: 0.0,
                maxVal: 360.0,
                icon: Icons.explore_rounded,
              ),

              const SizedBox(height: 12),

              // Section 2: Solar Geometry Parameters
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Solar Geometry & Angles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D)),
                ),
              ),

              _buildTextField(
                controller: _aoiController,
                label: 'Angle of Incidence',
                hint: 'e.g. 32.0',
                unit: '°',
                minVal: 0.0,
                maxVal: 180.0,
                icon: Icons.details_rounded,
              ),

              _buildTextField(
                controller: _zenithController,
                label: 'Solar Zenith Angle',
                hint: 'e.g. 42.5',
                unit: '°',
                minVal: 0.0,
                maxVal: 180.0,
                icon: Icons.brightness_high_rounded,
              ),

              _buildTextField(
                controller: _azimuthController,
                label: 'Solar Azimuth Angle',
                hint: 'e.g. 168.0',
                unit: '°',
                minVal: 0.0,
                maxVal: 360.0,
                icon: Icons.compass_calibration_rounded,
              ),

              const SizedBox(height: 20),

              // Predict Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitPrediction,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.bolt_rounded, size: 24),
                label: Text(
                  _isLoading ? 'Predicting Power...' : 'Predict Solar Power',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 6,
                ),
              ),

              const SizedBox(height: 20),

              // Error Display Box
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Output Result Card
              if (_predictedPower != null)
                Card(
                  color: const Color(0xFF1B382B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_rounded, color: Color(0xFF81C784)),
                            SizedBox(width: 8),
                            Text(
                              'Predicted Solar Power:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFA5D6A7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_predictedPower!.toStringAsFixed(2)} kW',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Estimated instantaneous photovoltaic energy generation.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
