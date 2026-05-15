import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../widgets/child_card.dart';
import 'child_profile_details_screen.dart';
import '../family/child_profile_details_screen.dart';

class MyInterestsScreen extends StatefulWidget {
  final String familyId;

  const MyInterestsScreen({super.key, required this.familyId});

  @override
  State<MyInterestsScreen> createState() => _MyInterestsScreenState();
}

class _MyInterestsScreenState extends State<MyInterestsScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<ChildModel>>(
      future: _dbService.getMyInterests(widget.familyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading interests',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
                ),
              ],
            ),
          );
        }

        final interests = snapshot.data ?? [];

        if (interests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No interests yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse children and express your interest',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: interests.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChildCard(
                  child: interests[index],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChildDetailScreen(
                          child: interests[index],
                          familyId: widget.familyId,
                        ),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}