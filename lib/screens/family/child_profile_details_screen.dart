import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/child_model.dart';
import '../../models/chat_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_messaging_screen.dart';
import '../../services/adoption_service.dart';

class ChildDetailScreen extends StatefulWidget {
  final ChildModel child;
  final String familyId;

  const ChildDetailScreen({
    super.key,
    required this.child,
    required this.familyId,
  });

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AdoptionService _adoptionService = AdoptionService();
  bool _isExpressingInterest = false;
  bool _isRequestingAdoption = false;

  // ── Orphanage rating state ───────────────────────────────────────────────
  double _userRating = 0;
  double _averageRating = 0;
  int _totalRatings = 0;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _loadOrphanageRating();
  }

  Future<void> _loadOrphanageRating() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.child.orphanageId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _averageRating = (data['averageRating'] ?? 0.0).toDouble();
          _totalRatings = data['totalRatings'] ?? 0;
        });
      }

      // Check if this family already rated
      final ratingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.child.orphanageId)
          .collection('ratings')
          .doc(widget.familyId)
          .get();

      if (ratingDoc.exists) {
        setState(() {
          _userRating = (ratingDoc.data()!['rating'] ?? 0.0).toDouble();
          _hasRated = true;
        });
      }
    } catch (e) {
      print('Error loading rating: $e');
    }
  }

  Future<void> _submitRating(double rating) async {
    try {
      final orphanageRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.child.orphanageId);

      final ratingRef = orphanageRef
          .collection('ratings')
          .doc(widget.familyId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final orphanageDoc = await transaction.get(orphanageRef);
        final existingRatingDoc = await transaction.get(ratingRef);

        double currentTotal = 0;
        int currentCount = 0;

        if (orphanageDoc.exists) {
          currentTotal = ((orphanageDoc.data()!['averageRating'] ?? 0.0) *
              (orphanageDoc.data()!['totalRatings'] ?? 0)).toDouble();
          currentCount = orphanageDoc.data()!['totalRatings'] ?? 0;
        }

        if (existingRatingDoc.exists) {
          // Update: remove old rating first
          final oldRating = (existingRatingDoc.data()!['rating'] ?? 0.0).toDouble();
          currentTotal -= oldRating;
          currentCount--;
        }

        final newTotal = currentTotal + rating;
        final newCount = currentCount + 1;
        final newAverage = newTotal / newCount;

        transaction.set(ratingRef, {
          'rating': rating,
          'familyId': widget.familyId,
          'createdAt': DateTime.now().toIso8601String(),
        });

        transaction.update(orphanageRef, {
          'averageRating': newAverage,
          'totalRatings': newCount,
        });
      });

      setState(() {
        _userRating = rating;
        _hasRated = true;
        // Optimistic update
        if (_totalRatings == 0) {
          _averageRating = rating;
          _totalRatings = 1;
        } else {
          _totalRatings++;
          _averageRating = ((_averageRating * (_totalRatings - 1)) + rating) / _totalRatings;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⭐ Thank you for rating!', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.amber[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showOrphanageProfilePopup() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double tempRating = _userRating;

    // Fetch orphanage full data
    DocumentSnapshot? orphanageDoc;
    try {
      orphanageDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.child.orphanageId)
          .get();
    } catch (_) {}

    final orphanageData = orphanageDoc?.data() as Map<String, dynamic>? ?? {};
    final paymentMethods = <Map<String, dynamic>>[];

    try {
      final pmSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.child.orphanageId)
          .collection('payment_methods')
          .get();
      paymentMethods.addAll(pmSnapshot.docs.map((d) => d.data()));
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6584), Color(0xFFFF8FA2)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.child.orphanageName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) {
                                          return Icon(
                                            i < _averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${_averageRating.toStringAsFixed(1)} ($_totalRatings)',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Info rows
                          _buildPopupInfoRow(Icons.location_on_outlined, 'Location',
                              orphanageData['location'] ?? widget.child.location, isDark),
                          const SizedBox(height: 10),
                          _buildPopupInfoRow(Icons.phone_outlined, 'Phone',
                              widget.child.orphanagePhone, isDark),
                          const SizedBox(height: 10),
                          _buildPopupInfoRow(Icons.email_outlined, 'Email',
                              widget.child.orphanageEmail, isDark),
                          const SizedBox(height: 22),

                          // Payment methods
                          if (paymentMethods.isNotEmpty) ...[
                            Text(
                              '💳 Donation Accounts',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...paymentMethods.map((method) {
                              final isBank = method['type'] == 'Bank Account';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43A047).withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF43A047).withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isBank ? Icons.account_balance_outlined : Icons.account_balance_wallet_outlined,
                                      color: const Color(0xFF43A047),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            method['type'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF43A047),
                                            ),
                                          ),
                                          Text(
                                            method['accountHolderName'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          if (isBank) ...[
                                            if ((method['bankName'] ?? '').isNotEmpty)
                                              Text(method['bankName'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                            if ((method['accountNumber'] ?? '').isNotEmpty)
                                              Text('Acc: ${method['accountNumber']}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                                            if ((method['iban'] ?? '').isNotEmpty)
                                              Text('IBAN: ${method['iban']}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                                          ] else ...[
                                            if ((method['walletProvider'] ?? '').isNotEmpty)
                                              Text(method['walletProvider'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                            if ((method['walletNumber'] ?? '').isNotEmpty)
                                              Text('ID: ${method['walletNumber']}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 22),
                          ],

                          // Rate this orphanage
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasRated ? '⭐ Your Rating' : '⭐ Rate this Orphanage',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hasRated
                                      ? 'You rated this orphanage. Tap to update.'
                                      : 'Help other families by sharing your experience.',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (i) {
                                    final starValue = i + 1.0;
                                    return GestureDetector(
                                      onTap: () {
                                        setSheetState(() => tempRating = starValue);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(
                                          tempRating >= starValue ? Icons.star_rounded : Icons.star_outline_rounded,
                                          color: Colors.amber,
                                          size: 36,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                if (tempRating > 0) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFFFC107)]),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: MaterialButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _submitRating(tempRating);
                                        },
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: Text(
                                          _hasRated ? 'Update Rating' : 'Submit Rating',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDonationSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String _donationType = 'Orphanage'; // 'Orphanage' or 'Child'

    // Fetch payment methods
    final paymentMethods = <Map<String, dynamic>>[];
    try {
      final pmSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.child.orphanageId)
          .collection('payment_methods')
          .get();
      paymentMethods.addAll(pmSnapshot.docs.map((d) => d.data()));
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Make a Donation',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Your generosity makes a difference',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Donate to selector
                          Text(
                            'Donate to',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => _donationType = 'Orphanage'),
                                  child: _buildDonationTypeCard(
                                    icon: Icons.home_outlined,
                                    label: 'Orphanage',
                                    subtitle: widget.child.orphanageName,
                                    isSelected: _donationType == 'Orphanage',
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setSheetState(() => _donationType = 'Child'),
                                  child: _buildDonationTypeCard(
                                    icon: Icons.child_care_outlined,
                                    label: 'Child',
                                    subtitle: widget.child.name,
                                    isSelected: _donationType == 'Child',
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Payment methods
                          if (paymentMethods.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.account_balance_outlined, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No payment methods available',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'This orphanage has not added any donation accounts yet.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Send your donation to',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...paymentMethods.map((method) {
                              final isBank = method['type'] == 'Bank Account';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43A047).withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFF43A047).withOpacity(0.25)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF43A047).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isBank ? Icons.account_balance_outlined : Icons.account_balance_wallet_outlined,
                                        color: const Color(0xFF43A047),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF43A047).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              method['type'] ?? '',
                                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF43A047)),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            method['accountHolderName'] ?? '',
                                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                          ),
                                          if (isBank) ...[
                                            if ((method['bankName'] ?? '').isNotEmpty)
                                              Text(method['bankName'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                            if ((method['accountNumber'] ?? '').isNotEmpty)
                                              _buildCopyRow('Acc: ${method['accountNumber']}', method['accountNumber'], isDark),
                                            if ((method['iban'] ?? '').isNotEmpty)
                                              _buildCopyRow('IBAN: ${method['iban']}', method['iban'], isDark),
                                          ] else ...[
                                            if ((method['walletProvider'] ?? '').isNotEmpty)
                                              Text(method['walletProvider'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                                            if ((method['walletNumber'] ?? '').isNotEmpty)
                                              _buildCopyRow('ID: ${method['walletNumber']}', method['walletNumber'], isDark),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 14),

                          // Donation note
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _donationType == 'Child'
                                        ? 'When donating for ${widget.child.name}, please include the child\'s name in your transfer note so the orphanage can allocate it correctly.'
                                        : 'Your donation will go to ${widget.child.orphanageName} and will be used to support all children in the orphanage.',
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue[700], height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDonationTypeCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)])
            : null,
        color: isSelected ? null : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF43A047) : Colors.grey[300]!,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isSelected ? Colors.white70 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(String displayText, String copyValue, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Copy to clipboard
        // Clipboard.setData(ClipboardData(text: copyValue));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $copyValue', style: GoogleFonts.poppins(fontSize: 12)),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Text(displayText, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500])),
          ),
          //const Icon(Icons.copy_outlined, size: 14, color: Color(0xFF43A047)),
        ],
      ),
    );
  }

  Future<void> _expressInterest() async {
    setState(() => _isExpressingInterest = true);
    final error = await _dbService.expressInterest(
      childId: widget.child.id,
      familyId: widget.familyId,
    );
    setState(() => _isExpressingInterest = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? '✅ Interest expressed successfully!', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: error != null ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _removeInterest() async {
    setState(() => _isExpressingInterest = true);
    final error = await _dbService.removeInterest(
      childId: widget.child.id,
      familyId: widget.familyId,
    );
    setState(() => _isExpressingInterest = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? '✅ Interest removed', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: error != null ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _showAdoptionRequestDialog() async {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Request Adoption',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell us why you want to adopt ${widget.child.name}',
                  style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Enter your reason...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6584), Color(0xFFFF8FA2)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a reason', style: GoogleFonts.poppins(fontSize: 12)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  setState(() => _isRequestingAdoption = true);
                  final authService = Provider.of<AuthService>(context, listen: false);
                  final userData = await authService.getCurrentUserData();

                  if (userData == null) {
                    setState(() => _isRequestingAdoption = false);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: Could not load your data', style: GoogleFonts.poppins(fontSize: 12)),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }

                  final error = await _adoptionService.createAdoptionRequest(
                    childId: widget.child.id,
                    childName: widget.child.name,
                    familyId: widget.familyId,
                    familyName: userData.name,
                    familyEmail: userData.email,
                    familyPhone: userData.phone,
                    orphanageId: widget.child.orphanageId,
                    orphanageName: widget.child.orphanageName,
                    reasonForAdoption: reasonController.text.trim(),
                  );

                  setState(() => _isRequestingAdoption = false);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error ?? '✅ Adoption request submitted successfully!',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        backgroundColor: error != null ? Colors.red : Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: _isRequestingAdoption
                    ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
                    : Text('Submit Request', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openChat() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))),
                const SizedBox(height: 16),
                Text('Opening chat...', style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          ),
        ),
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getCurrentUserData();
      if (userData == null) throw Exception('Unable to load user data');

      final chatService = ChatService();
      final chatId = await chatService.createOrGetChat(
        familyId: widget.familyId,
        familyName: userData.name,
        orphanageId: widget.child.orphanageId,
        orphanageName: widget.child.orphanageName,
        childId: widget.child.id,
        childName: widget.child.name,
      );

      final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Chat creation failed');

      final chat = ChatModel.fromMap(chatDoc.data()!);

      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatMessagingScreen(chat: chat, currentUser: userData)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to open chat. Please try again.', style: GoogleFonts.poppins(fontSize: 13))),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _openChat),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInterested = widget.child.interestedFamilies.contains(widget.familyId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF6C63FF),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'child_${widget.child.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.child.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.child_care, size: 80, color: Colors.grey)),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    widget.child.name,
                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 8),

                  // Basic Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.cake_outlined, '${widget.child.age} years', Colors.blue),
                      _buildInfoChip(
                        widget.child.gender == 'Male' ? Icons.male : Icons.female,
                        widget.child.gender,
                        widget.child.gender == 'Male' ? Colors.blue : const Color(0xFFFF6584),
                      ),
                      _buildInfoChip(Icons.favorite_outline, widget.child.healthStatus, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection('About ${widget.child.name}', widget.child.description, Icons.info_outline, isDark),
                  const SizedBox(height: 20),
                  _buildSection('Location', widget.child.location, Icons.location_on_outlined, isDark),
                  const SizedBox(height: 20),

                  // Orphanage Info — tappable to open popup
                  GestureDetector(
                    onTap: _showOrphanageProfilePopup,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_outlined, color: Color(0xFF6C63FF), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orphanage',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(widget.child.orphanageName, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700])),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ...List.generate(5, (i) => Icon(
                                      i < _averageRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 14,
                                    )),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_averageRating.toStringAsFixed(1)} · $_totalRatings reviews',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('View', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.contact_phone_outlined, color: Color(0xFF6C63FF), size: 22),
                            const SizedBox(width: 10),
                            Text('Contact Information', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildContactRow(Icons.phone, widget.child.orphanagePhone, isDark),
                        const SizedBox(height: 8),
                        _buildContactRow(Icons.email, widget.child.orphanageEmail, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Interest count
                  if (widget.child.interestedFamilies.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6584), Color(0xFFFF8FA2)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            '${widget.child.interestedFamilies.length} families interested',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Donate Button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFF43A047).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showDonationSheet,
                        icon: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 20),
                        label: Text('Donate', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Express/Remove Interest
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isInterested ? [Colors.grey, Colors.grey.shade600] : [const Color(0xFFFF6584), const Color(0xFFFF8FA2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: (isInterested ? Colors.grey : const Color(0xFFFF6584)).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isExpressingInterest ? null : (isInterested ? _removeInterest : _expressInterest),
                        icon: _isExpressingInterest
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                            : Icon(isInterested ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 20),
                        label: Text(
                          isInterested ? 'Remove Interest' : 'Express Interest',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Chat Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                        label: Text('Chat with Orphanage', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Adoption Request Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6584), Color(0xFFFF8FA2)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF6584).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showAdoptionRequestDialog,
                        icon: const Icon(Icons.assignment_turned_in, color: Colors.white, size: 20),
                        label: Text('Request Final Adoption', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 22),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[700]))),
      ],
    );
  }
}