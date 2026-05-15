import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/adoption_request_model.dart';
import '../../services/database_service.dart';

class AdoptionRequestsFamilyScreen extends StatefulWidget {
  final String familyId;

  const AdoptionRequestsFamilyScreen({
    super.key,
    required this.familyId,
  });

  @override
  State<AdoptionRequestsFamilyScreen> createState() =>
      _AdoptionRequestsFamilyScreenState();
}

class _AdoptionRequestsFamilyScreenState
    extends State<AdoptionRequestsFamilyScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Adoption Requests',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<List<AdoptionRequest>>(
        stream: _dbService.getAdoptionRequestsByFamily(widget.familyId),
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
                  const SizedBox(height: 14),
                  Text(
                    'Error loading requests',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 14),
                  Text(
                    'No adoption requests yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send adoption requests from child profiles',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildRequestCard(request, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(AdoptionRequest request, bool isDark) {
    final isCompleted = request.requestStatus == 'completed';
    final isRejected = request.requestStatus.contains('rejected');
    final isPending = request.requestStatus == 'pending_orphanage_approval';
    final isPendingAdmin = request.requestStatus == 'pending_admin_approval';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          request.childName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          'To: ${request.orphanageName}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withOpacity(0.1)
                : isRejected
                ? Colors.red.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isCompleted
                ? 'Completed'
                : isRejected
                ? 'Rejected'
                : isPendingAdmin
                ? 'Admin Review'
                : 'Pending',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isCompleted
                  ? Colors.green
                  : isRejected
                  ? Colors.red
                  : Colors.orange,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Orphanage Info Section
                Text(
                  'Orphanage Information',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Name', request.orphanageName, isDark),
                const SizedBox(height: 16),

                // Your Request Details
                Text(
                  'Your Reason',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    request.reasonForAdoption,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Background Check Status
                _buildInfoRow(
                  'Background Check',
                  request.backgroundCheckStatus.replaceAll('_', ' ').toUpperCase(),
                  isDark,
                ),
                const SizedBox(height: 16),

                // Request Status Timeline
                Text(
                  'Request Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusStep('Sent', true, isDark),
                      _buildStatusStep(
                        'Orphanage Review',
                        !isPending && !isRejected,
                        isDark,
                      ),
                      _buildStatusStep(
                        'Admin Approval',
                        isCompleted,
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Rejection Reason if rejected
                if (isRejected && request.orphanageRejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.orphanageRejectionReason!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Completion Message
                if (isCompleted) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Congratulations! Your adoption request was approved!',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String label, bool isComplete, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? const Color(0xFF6C63FF)
                  : isDark
                  ? Colors.grey[700]
                  : Colors.grey[300],
            ),
            child: Icon(
              isComplete ? Icons.check : Icons.schedule,
              size: 14,
              color: isComplete ? Colors.white : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isComplete
                  ? const Color(0xFF6C63FF)
                  : isDark
                  ? Colors.grey[500]
                  : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}