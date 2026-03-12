import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ScanSheetScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const ScanSheetScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<ScanSheetScreen> createState() => _ScanSheetScreenState();
}

class _ScanSheetScreenState extends State<ScanSheetScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isExtracting = false;

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100,
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
      });
    }
  }

  Future<void> _extractData() async {
    if (_image == null) return;

    setState(() {
      _isExtracting = true;
    });

    try {
      const apiKey = 'AIzaSyDiW181U3W8C4qF-ev-f_JdJykr6EftZtA';
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final prompt = TextPart('''
        You are an expert data entry assistant. Analyze this scanned student answer sheet.
        Extract the Student Name, Roll Number, Marks for Q1 to Q15, and Total Marks.
        If a question has no marks or is missing, use 0.
        Return ONLY a JSON object matching this exact structure:
        {
          "student_name": "String",
          "roll_number": "String",
          "q1": 0, "q2": 0, "q3": 0, "q4": 0, "q5": 0,
          "q6": 0, "q7": 0, "q8": 0, "q9": 0, "q10": 0,
          "q11": 0, "q12": 0, "q13": 0, "q14": 0, "q15": 0,
          "total_marks": 0
        }
      ''');

      final imageBytes = await _image!.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final jsonString = response.text;

      if (jsonString != null) {
        final Map<String, dynamic> extractedData = jsonDecode(jsonString);
        extractedData['subject_id'] = widget.subjectId;

        await Supabase.instance.client
            .from('student_marks')
            .insert(extractedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Marks extracted and saved successfully!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error extracting data: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.subjectName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: _image == null
            ? _buildNoImageState()
            : _buildImagePreviewState(),
      ),
    );
  }

  Widget _buildNoImageState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.document_scanner_outlined,
          size: 80,
          color: Colors.blueAccent, // Blue icon
        ),
        const SizedBox(height: 24),
        const Text(
          'Scan a student answer sheet\nto extract marks automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _takePhoto,
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text(
            'Take Photo',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent, // Blue button
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewState() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade800, width: 2),
              borderRadius: BorderRadius.circular(16),
              color: Colors
                  .grey
                  .shade900, // Slightly lighter black for image container
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_image!, fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_isExtracting)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 16),
                    Text(
                      'Gemini is analyzing the sheet...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.blueAccent,
                        ),
                        label: const Text(
                          'Retake',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.blueAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _extractData,
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Extract',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
