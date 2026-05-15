import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/child_model.dart';
import '../../services/database_service.dart';
import '../../widgets/child_card.dart';
import 'add_child_screen.dart';
import 'interested_families_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/conversations_list_screen.dart';
import '../orphanage//adoption_requests_screen.dart';

class OrphanageHomeScreen extends StatefulWidget {
  final UserModel user;

  const OrphanageHomeScreen({super.key, required this.user});

  @override
  State<OrphanageHomeScreen> createState() => _OrphanageHomeScreenState();
}

class _OrphanageHomeScreenState extends State<OrphanageHomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteChild(ChildModel child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Child',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete ${child.name}\'s profile? This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final error = await _dbService.deleteChild(child.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? '✅ Child profile deleted successfully', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: error != null ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showChildOptions(ChildModel child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(child.photoUrl),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '${child.age} years • ${child.gender}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),

              _buildOptionTile(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Edit Profile',
                subtitle: 'Update child information',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddChildScreen(
                        user: widget.user,
                        childToEdit: child,
                      ),
                    ),
                  );
                },
              ),

              _buildOptionTile(
                icon: Icons.people_outline,
                iconColor: Colors.blue,
                title: 'Interested Families',
                subtitle: '${child.interestedFamilies.length} families interested',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InterestedFamiliesScreen(child: child),
                    ),
                  );
                },
              ),

              _buildOptionTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red,
                title: 'Delete Profile',
                subtitle: 'Permanently remove this child',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _deleteChild(child);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
    );
  }

  Widget _buildMyChildrenTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search children...',
                hintStyle: GoogleFonts.poppins(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C63FF), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: isDark ? Colors.grey[500] : Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: StreamBuilder<List<ChildModel>>(
            stream: _dbService.getChildrenByOrphanage(widget.user.uid),
            builder: (context, snapshot) {
              final children = snapshot.data ?? [];
              final totalInterests = children.fold<int>(
                0,
                    (sum, child) => sum + child.interestedFamilies.length,
              );

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      icon: Icons.child_care_rounded,
                      value: children.length.toString(),
                      label: 'Total Children',
                    ),
                    Container(
                      width: 2,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    _buildStatColumn(
                      icon: Icons.favorite_rounded,
                      value: totalInterests.toString(),
                      label: 'Total Interests',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<List<ChildModel>>(
            stream: _dbService.getChildrenByOrphanage(widget.user.uid),
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
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.error_outline, size: 45, color: Colors.red[300]),
                      ),
                      const SizedBox(height: 14),
                      Text('Error loading children', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        'Please check your connection',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final allChildren = snapshot.data ?? [];

              final children = _searchQuery.isEmpty
                  ? allChildren
                  : allChildren.where((child) {
                return child.name.toLowerCase().contains(_searchQuery) ||
                    child.gender.toLowerCase().contains(_searchQuery) ||
                    child.age.toString().contains(_searchQuery);
              }).toList();

              if (children.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6C63FF).withOpacity(0.1),
                              const Color(0xFFFF6584).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _searchQuery.isEmpty ? Icons.child_care_rounded : Icons.search_off_rounded,
                          size: 60,
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _searchQuery.isEmpty ? 'No children added yet' : 'No children found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Tap the + button below\nto add your first child'
                            : 'Try a different search term',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF6C63FF),
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChildCard(
                        child: child,
                        showInterestCount: true,
                        onTap: () => _showChildOptions(child),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'OrphanConnect',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        centerTitle: true,
      ),
      body: _selectedIndex == 0
          ? _buildMyChildrenTab()
          : _selectedIndex == 1
          ? AdoptionRequestsOrphanageScreen(orphanageId: widget.user.uid)
          : _selectedIndex == 2
          ? ConversationsListScreen(user: widget.user)
          : ProfileScreen(user: widget.user),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care_outlined, size: 24),
            activeIcon: Icon(Icons.child_care, size: 24),
            label: 'Children',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined, size: 24),
            activeIcon: Icon(Icons.assignment, size: 24),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: 24),
            activeIcon: Icon(Icons.chat_bubble, size: 24),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            activeIcon: Icon(Icons.person, size: 24),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF8E84FF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddChildScreen(user: widget.user)),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        ),
      )
          : null,
    );
  }
}