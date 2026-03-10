import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'scan_sheet_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const SubjectDetailsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  bool _isExporting = false;

  // Function to generate and save the Excel file
  Future<void> _exportToExcel(List<Map<String, dynamic>> marks) async {
    setState(() => _isExporting = true);

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // 1. Create Headers
      List<String> headers = ['Student Name', 'Roll Number'];
      for (int i = 1; i <= 15; i++) {
        headers.add('Q$i');
      }
      headers.add('Total Marks');
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // 2. Add Data Rows
      for (var student in marks) {
        List<CellValue> row = [
          TextCellValue(student['student_name']?.toString() ?? 'Unknown'),
          TextCellValue(student['roll_number']?.toString() ?? 'N/A'),
        ];
        for (int i = 1; i <= 15; i++) {
          row.add(IntCellValue(student['q$i'] ?? 0));
        }
        row.add(IntCellValue(student['total_marks'] ?? 0));

        sheetObject.appendRow(row);
      }

      // 3. Save the file to the device
      var fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      // On a real Android device, you might want to use the Downloads folder,
      // but Documents is universally safe for both iOS and Android to avoid permission crashes initially.
      final path = '${directory.path}/${widget.subjectName}_Marks.xlsx';

      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Excel saved to Documents: ${widget.subjectName}_Marks.xlsx',
            ),
            backgroundColor: Colors.black,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.subjectName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Listen to the student_marks table for THIS specific subject
        stream: Supabase.instance.client
            .from('student_marks')
            .stream(primaryKey: ['id'])
            .eq('subject_id', widget.subjectId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final marks = snapshot.data ?? [];

          if (marks.isEmpty) {
            return const Center(
              child: Text(
                'No marks extracted yet.\nTap the camera icon to scan a sheet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              // Export Button Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${marks.length} Students Scanned',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _exportToExcel(marks),
                            icon: const Icon(
                              Icons.download,
                              color: Colors.black,
                              size: 18,
                            ),
                            label: const Text(
                              'Export Excel',
                              style: TextStyle(color: Colors.black),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // The Data Table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade50,
                      ),
                      columns: [
                        const DataColumn(
                          label: Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const DataColumn(
                          label: Text(
                            'Roll No.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (int i = 1; i <= 15; i++)
                          DataColumn(
                            label: Text(
                              'Q$i',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const DataColumn(
                          label: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                      rows: marks.map((student) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(student['student_name']?.toString() ?? '-'),
                            ),
                            DataCell(
                              Text(student['roll_number']?.toString() ?? '-'),
                            ),
                            for (int i = 1; i <= 15; i++)
                              DataCell(Text(student['q$i']?.toString() ?? '0')),
                            DataCell(
                              Text(
                                student['total_marks']?.toString() ?? '0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Floating Action Button to open the Camera
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanSheetScreen(
                subjectId: widget.subjectId,
                subjectName: widget.subjectName,
              ),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Sheet'),
      ),
    );
  }
}
