import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/ecore_setup.dart';

class ClimaGameTestScreen extends StatefulWidget {
  @override
  _ClimaGameTestScreenState createState() => _ClimaGameTestScreenState();
}

class _ClimaGameTestScreenState extends State<ClimaGameTestScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ClimaGame Test'),
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ClimaGame Setup',
                      style: GoogleFonts.questrial(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use these buttons to set up and manage ClimaGame ecores for testing.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createSampleEcores,
              icon: Icon(Icons.add),
              label: Text('Create Sample Ecores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearAllEcores,
              icon: Icon(Icons.delete),
              label: Text('Clear All Ecores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _listAllEcores,
              icon: Icon(Icons.list),
              label: Text('List All Ecores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSampleEcores() async {
    setState(() => _isLoading = true);

    try {
      await EcoreSetup.createSampleEcores();
      _showSnackBar('✅ Sample ecores created successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error creating ecores: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllEcores() async {
    setState(() => _isLoading = true);

    try {
      await EcoreSetup.clearAllEcores();
      _showSnackBar('✅ All ecores cleared successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Error clearing ecores: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _listAllEcores() async {
    setState(() => _isLoading = true);

    try {
      await EcoreSetup.listAllEcores();
      _showSnackBar('✅ Ecores listed in console!', Colors.blue);
    } catch (e) {
      _showSnackBar('❌ Error listing ecores: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }
}