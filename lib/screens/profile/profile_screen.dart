import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/support_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/image_service.dart';
import '../../services/support_service.dart';
import '../../screens/auth//login_screen.dart';
import 'create_support_ticket_screen.dart';
import 'support_tickets_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final SupportService _supportService = SupportService();
  final DatabaseService _dbService = DatabaseService();
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _profileImageUrl = widget.user.photoUrl ?? '';
  }

  Future<void> _pickAndUploadProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _isUploadingImage = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Text('Uploading profile photo...', style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 30),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      final uploadedUrl = await ImageService.uploadImage(File(image.path));

      if (uploadedUrl != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.updateUserPhoto(widget.user.uid, uploadedUrl);

        setState(() {
          _profileImageUrl = uploadedUrl;
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Profile photo updated!', style: GoogleFonts.poppins(fontSize: 12)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        setState(() => _isUploadingImage = false);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to upload image', style: GoogleFonts.poppins(fontSize: 12)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _currentUser.name);
    final phoneController = TextEditingController(text: _currentUser.phone);
    final locationController = TextEditingController(text: _currentUser.location);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 10),
              Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneController,
                  style: GoogleFonts.poppins(fontSize: 13),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: locationController,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Location',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  final error = await authService.updateUserProfile(
                    uid: widget.user.uid,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    location: locationController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error ?? '✅ Profile updated successfully!',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        backgroundColor: error != null ? Colors.red : Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    if (error == null) {
                      setState(() {
                        _currentUser = UserModel(
                          uid: _currentUser.uid,
                          email: _currentUser.email,
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          location: locationController.text.trim(),
                          role: _currentUser.role,
                          createdAt: _currentUser.createdAt,
                          photoUrl: _currentUser.photoUrl,
                        );
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text('Save', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    String selectedType = 'Bank Account';
    final accountNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final bankNameController = TextEditingController();
    final ibanController = TextEditingController();
    final walletNumberController = TextEditingController();
    final walletProviderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF43A047), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Add Payment Method', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type selector
                    Row(
                      children: ['Bank Account', 'Wallet'].map((type) {
                        final isSelected = selectedType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedType = type),
                            child: Container(
                              margin: EdgeInsets.only(right: type == 'Bank Account' ? 6 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)])
                                    : null,
                                color: isSelected ? null : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF43A047) : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    type == 'Bank Account' ? Icons.account_balance_outlined : Icons.account_balance_wallet_outlined,
                                    size: 16,
                                    color: isSelected ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    type == 'Bank Account' ? 'Bank' : 'Wallet',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    if (selectedType == 'Bank Account') ...[
                      _buildDialogTextField(accountNameController, 'Account Holder Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildDialogTextField(bankNameController, 'Bank Name', Icons.account_balance_outlined),
                      const SizedBox(height: 12),
                      _buildDialogTextField(accountNumberController, 'Account Number', Icons.numbers_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildDialogTextField(ibanController, 'IBAN (optional)', Icons.credit_card_outlined),
                    ] else ...[
                      _buildDialogTextField(accountNameController, 'Account Holder Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildDialogTextField(walletProviderController, 'Wallet Provider (e.g. PayPal)', Icons.wallet_outlined),
                      const SizedBox(height: 12),
                      _buildDialogTextField(walletNumberController, 'Wallet Number / ID', Icons.tag_outlined, keyboardType: TextInputType.phone),
                    ],
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
                    gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      // Build the payload based on type
                      final Map<String, dynamic> data = {
                        'type': selectedType,
                        'accountHolderName': accountNameController.text.trim(),
                      };

                      if (selectedType == 'Bank Account') {
                        data['bankName'] = bankNameController.text.trim();
                        data['accountNumber'] = accountNumberController.text.trim();
                        if (ibanController.text.trim().isNotEmpty) {
                          data['iban'] = ibanController.text.trim();
                        }
                      } else {
                        data['walletProvider'] = walletProviderController.text.trim();
                        data['walletNumber'] = walletNumberController.text.trim();
                      }

                      final error = await _dbService.savePaymentMethod(
                        orphanageId: _currentUser.uid,
                        paymentData: data,
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error ?? '✅ Payment method saved!',
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: Text('Save', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePaymentMethod(String methodId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Method', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Text('Are you sure you want to remove this payment method?', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await _dbService.deletePaymentMethod(
                orphanageId: _currentUser.uid,
                methodId: methodId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? '🗑️ Removed successfully', style: GoogleFonts.poppins(fontSize: 12)),
                    backgroundColor: error != null ? Colors.red : Colors.grey[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isBank = method['type'] == 'Bank Account';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
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
                // Type badge
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
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
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
          // Delete button
          IconButton(
            onPressed: () => _confirmDeletePaymentMethod(method['id']),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Avatar with edit button
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                          ? Text(
                        _currentUser.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6C63FF),
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Text(
              _currentUser.name,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentUser.role == 'family'
                      ? [const Color(0xFF6C63FF), const Color(0xFF8E84FF)]
                      : [const Color(0xFFFF6584), const Color(0xFFFF8FA2)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentUser.role == 'family' ? '👨‍👩‍👧 Family' : '🏠 Orphanage',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
            const SizedBox(height: 26),

            _buildInfoCard(Icons.email_outlined, 'Email', _currentUser.email),
            const SizedBox(height: 10),
            _buildInfoCard(Icons.phone_outlined, 'Phone', _currentUser.phone),
            const SizedBox(height: 10),
            _buildInfoCard(Icons.location_on_outlined, 'Location', _currentUser.location),
            const SizedBox(height: 26),

            // ── Donation Accounts (orphanage only) ───────────────────────
            if (_currentUser.role == 'orphanage') ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF43A047).withOpacity(0.08),
                      const Color(0xFF66BB6A).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF43A047).withOpacity(0.25), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF43A047), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Donation Accounts',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                              ),
                              Text(
                                'Bank accounts & wallets for donations',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Live list from Firestore
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _dbService.getPaymentMethods(_currentUser.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF43A047)),
                            ),
                          );
                        }

                        final methods = snapshot.data ?? [];

                        if (methods.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_outlined, size: 36, color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Text('No payment methods added yet', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                                const SizedBox(height: 2),
                                Text(
                                  'Add a bank account or wallet so donors can reach you',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: methods.map(_buildPaymentMethodCard).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Add button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF43A047).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: MaterialButton(
                          onPressed: _showAddPaymentMethodDialog,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add Bank / Wallet',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
            ],

            // Support Center Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.08),
                    const Color(0xFF8E84FF).withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2), width: 1.5),
              ),
              child: StreamBuilder<List<SupportTicket>>(
                stream: _supportService.getUserSupportTickets(_currentUser.uid),
                builder: (context, snapshot) {
                  final ticketCount = snapshot.data?.length ?? 0;
                  final openTickets = snapshot.data?.where((t) => !t.isResolved).length ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: Color(0xFF6C63FF), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Support Center',
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: ticketCount.toString(),
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF6C63FF)),
                                      ),
                                      TextSpan(
                                        text: ' ticket${ticketCount != 1 ? 's' : ''}',
                                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      if (openTickets > 0) ...[
                                        TextSpan(text: ' • ', style: GoogleFonts.poppins(color: Colors.grey[500])),
                                        TextSpan(
                                          text: '$openTickets open',
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: MaterialButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CreateSupportTicketScreen(user: _currentUser)),
                                  );
                                },
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_rounded, color: Color(0xFF6C63FF), size: 20),
                                    const SizedBox(width: 6),
                                    Text('New Ticket', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF6C63FF))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: MaterialButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SupportTicketsListScreen(userId: _currentUser.uid)),
                                  );
                                },
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text('View All', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text('Logout', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text('Logout', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await authService.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                  label: Text('Logout', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}