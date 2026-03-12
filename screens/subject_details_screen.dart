import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _exportToExcel(List<Map<String, dynamic>> marks) async {
    setState(() => _isExporting = true);

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      List<String> headers = ['Student Name', 'Roll Number'];
      for (int i = 1; i <= 15; i++) {
        headers.add('Q$i');
      }
      headers.add('Total Marks');
      sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

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

      var fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${widget.subjectName}_Marks.xlsx';

      File file = File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      if (mounted) {
        setState(() => _isExporting = false);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: '${widget.subjectName} Marks Export');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('student_marks')
            .stream(primaryKey: ['id'])
            .eq('subject_id', widget.subjectId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          final marks = snapshot.data ?? [];

          if (marks.isEmpty) {
            return const Center(
              child: Text(
                'No marks extracted yet.\nTap the camera icon to scan a sheet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
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
                        color: Colors.white70,
                      ),
                    ),
                    _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.blueAccent,
                              strokeWidth: 2,
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _exportToExcel(marks),
                            icon: const Icon(
                              Icons.share,
                              color: Colors.blueAccent,
                              size: 18,
                            ),
                            label: const Text(
                              'Share Excel',
                              style: TextStyle(color: Colors.blueAccent),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.blue.shade800),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade800),

              // The Data Table
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.grey.shade800),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade900,
                        ),
                        columns: [
                          const DataColumn(
                            label: Text(
                              'Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Roll No.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          for (int i = 1; i <= 15; i++)
                            DataColumn(
                              label: Text(
                                'Q$i',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          const DataColumn(
                            label: Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ],
                        rows: marks.map((student) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  student['student_name']?.toString() ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(
                                Text(
                                  student['roll_number']?.toString() ?? '-',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              for (int i = 1; i <= 15; i++)
                                DataCell(
                                  Text(
                                    student['q$i']?.toString() ?? '0',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              DataCell(
                                Text(
                                  student['total_marks']?.toString() ?? '0',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
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
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
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
