import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'subject_details_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  // Show the dialog to add a new subject
  void _showAddSubjectDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Crisp white for dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          title: const Text(
            'New Subject',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.black),
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: 'e.g., Mathematics',
              hintStyle: const TextStyle(color: Colors.black54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () async {
                final enteredName = nameController.text.trim();
                if (enteredName.isNotEmpty) {
                  // Insert into Supabase
                  await Supabase.instance.client.from('subjects').insert({
                    'name': enteredName,
                  });

                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Subjects',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Real-time stream from Supabase, ordered by creation date
        stream: Supabase.instance.client
            .from('subjects')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading subjects',
                style: TextStyle(color: Colors.red[700]),
              ),
            );
          }

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return const Center(
              child: Text(
                'No subjects yet.\nTap + to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          // Display subjects as a grid of folders
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubjectDetailsScreen(
                        // Changed from ScanSheetScreen
                        subjectId: subject['id'],
                        subjectName: subject['name'],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.folder_open_rounded,
                        color: Colors.black87,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          subject['name'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Circular Black FAB on White Background
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation:
            2, // Added a tiny bit of elevation so it pops against the white
        onPressed: () => _showAddSubjectDialog(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
