// ============================================
// FILE: lib/screens/friends_page.dart (DARK THEME UI UPDATE ONLY)
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/friend_request.dart';
import '../../models/user.dart' as app_user;
import '../../services/friend_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/logger.dart';
import '../../utils/error_handler.dart';
import 'friend_profile_page.dart';
import '../../widgets/qr_code_display.dart';
import 'qr_scanner_page.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final _friendService = FriendService();
  final _authService = FirebaseAuthService();

  List<app_user.User> _allFriends = [];
  List<app_user.User> _filteredFriends = [];

  // 🎨 Theme colors (same as Dashboard/Calendar)
  static const Color kBg = Color(0xFF0E141B);
  static const Color kAppBarBg = Color(0xFF0B0F14);
  static const Color kSurface = Color(0xFF151D27);
  static const Color kSurface2 = Color(0xFF1B2430);
  static const Color kBorder = Color(0xFF263241);

  static const Color kText = Color(0xFFF2F4F8);
  static const Color kMuted = Color(0xFF9AA7B4);

  static const Color kPrimary = Color(0xFF7C4DFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {});
    });
    Logger.navigation('Dashboard', 'FriendsPage');
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final currentUserId = _authService.currentUserId;
      if (currentUserId != null) {
        final friends =
            await _friendService.getFriendsWithDetails(currentUserId);
        setState(() {
          _allFriends = friends;
          _filteredFriends = List<app_user.User>.from(_allFriends);
        });
      }
    } catch (e) {
      Logger.error('Failed to load friends', e);
    }
  }

  void _searchFriends(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredFriends = List<app_user.User>.from(_allFriends);
        return;
      }

      _filteredFriends = _allFriends.where((u) {
        final name = u.name.toLowerCase();
        final email = u.email.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  void _removeFriend(app_user.User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('Remove Friend', style: TextStyle(color: kText)),
        content: Text(
          'Are you sure you want to remove ${user.name}?',
          style: const TextStyle(color: kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final currentUserId = _authService.currentUserId!;
                await _friendService.removeFriend(
                  userId: currentUserId,
                  friendId: user.id,
                );

                setState(() {
                  _allFriends.removeWhere((f) => f.id == user.id);
                  _filteredFriends.removeWhere((f) => f.id == user.id);
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.name} removed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ErrorHandler.getErrorMessage(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddFriendOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Friend',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kText,
              ),
            ),
            const SizedBox(height: 24),

            // Add by Email
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.email,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search by Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Find friends by email address',
                            style: TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Color.fromRGBO(242, 244, 248, 1)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scan QR Code
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showQRScanner();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan QR Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan friend\'s QR code',
                            style: TextStyle(fontSize: 13, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: kMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: Divider(color: kBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: kMuted)),
                ),
                Expanded(child: Divider(color: kBorder)),
              ],
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showMyQRCode();
              },
              icon: const Icon(Icons.qr_code_2, color: kPrimary),
              label: const Text('Generate My QR Code',
                  style: TextStyle(color: kText)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kBorder),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );
  }

  void _showMyQRCode() {
    final currentUser = _authService.currentUser;

    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) => QRCodeDisplay(
        userId: currentUser.id,
        userName: currentUser.name,
        userEmail: currentUser.email,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUserId;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view friends'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
          backgroundColor: kAppBarBg,
          elevation: 0,
          title: const Text(
            'Friends',
            style: TextStyle(
              color: kText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add, color: kPrimary),
              onPressed: _showAddFriendOptions,
              tooltip: 'Add Friend',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: kPrimary,
            labelColor: kPrimary,
            unselectedLabelColor: kMuted,
            tabs: [
              const Tab(text: 'My Friends'),
              const Tab(text: 'Find Friends'),
              Tab(
                child: StreamBuilder<List<FriendRequest>>(
                  stream: _friendService.getIncomingRequests(currentUserId),
                  builder: (context, snapshot) {
                    final requestCount = snapshot.data?.length ?? 0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Requests'),
                        if (requestCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$requestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          )),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyFriendsTab(),
          _buildFindFriendsTab(currentUserId),
          _buildRequestsTab(currentUserId),
        ],
      ),
    );
  }

  // TAB 1: MY FRIENDS
  Widget _buildMyFriendsTab() {
    return Column(
      children: [
        Container(
          color: kBg,
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: kText),
            decoration: InputDecoration(
              hintText: 'Search friends...',
              hintStyle: const TextStyle(color: kMuted),
              prefixIcon: const Icon(Icons.search, color: kMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: kMuted),
                      onPressed: () {
                        _searchController.clear();
                        _searchFriends('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimary, width: 1.2),
              ),
            ),
            onChanged: _searchFriends,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'My Friends (${_filteredFriends.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kText,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredFriends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No friends yet'
                            : 'No friends found',
                        style: const TextStyle(fontSize: 16, color: kMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Tap + to add your first friend!'
                            : 'Try a different search',
                        style: const TextStyle(fontSize: 14, color: kMuted),
                      ),
                    ],
                  ),
                )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.8, 0.8))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _filteredFriends[index];
                    return _buildFriendCard(friend)
                        .animate()
                        .fadeIn(
                            delay: (50 * index).ms,
                            duration: 300.ms) // ✅ Staggered
                        .slideX(begin: 0.2, delay: (50 * index).ms);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(app_user.User friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: kPrimary,
                child: Text(
                  friend.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (friend.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: kSurface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: friend.isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      friend.statusText,
                      style: const TextStyle(fontSize: 13, color: kMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kMuted),
            color: kSurface,
            onSelected: (value) {
              if (value == 'remove') {
                _removeFriend(friend);
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendProfilePage(friend: friend),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: kText),
                    SizedBox(width: 12),
                    Text('View Profile', style: TextStyle(color: kText)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Remove Friend', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // TAB 2: FIND FRIENDS
  Widget _buildFindFriendsTab(String currentUserId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add New Friend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you want to add a friend',
            style: TextStyle(fontSize: 14, color: kMuted),
          ),
          _buildAddMethodCard(
            icon: Icons.email,
            iconColor: kPrimary,
            title: 'Search by Email',
            description: 'Find and add friends by email address',
            onTap: () => _showSearchByEmailDialog(currentUserId),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
          const SizedBox(height: 16),
          _buildAddMethodCard(
            icon: Icons.qr_code_scanner,
            iconColor: kPrimary,
            title: 'Scan QR Code',
            description: 'Scan your friend\'s QR code to connect instantly',
            onTap: _showQRScanner,
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Divider(color: kBorder)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: kMuted)),
              ),
              Expanded(child: Divider(color: kBorder)),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 64, color: kPrimary),
                const SizedBox(height: 16),
                const Text(
                  'Share Your QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Let others scan your unique QR code',
                  style: TextStyle(fontSize: 13, color: kMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showMyQRCode,
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Show My QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchByEmailDialog(String currentUserId) async {
    final searchController = TextEditingController();
    List<app_user.User> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kSurface,
          title: const Text('Search Friends', style: TextStyle(color: kText)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: kText),
                  decoration: InputDecoration(
                    labelText: 'Email or Name',
                    labelStyle: const TextStyle(color: kMuted),
                    hintText: 'friend@example.com',
                    hintStyle: const TextStyle(color: kMuted),
                    prefixIcon: const Icon(Icons.search, color: kMuted),
                    filled: true,
                    fillColor: kSurface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimary, width: 1.2),
                    ),
                  ),
                  onChanged: (value) async {
                    if (value.trim().isEmpty) {
                      setDialogState(() {
                        searchResults = [];
                      });
                      return;
                    }

                    setDialogState(() {
                      isSearching = true;
                    });

                    try {
                      final results = await _friendService.searchUsers(
                        query: value,
                        currentUserId: currentUserId,
                      );

                      setDialogState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    } catch (e) {
                      setDialogState(() {
                        isSearching = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const CircularProgressIndicator()
                else if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimary,
                            child: Text(
                              user.initials,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user.name,
                              style: const TextStyle(color: kText)),
                          subtitle: Text(user.email,
                              style: const TextStyle(color: kMuted)),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _friendService.sendFriendRequest(
                                  senderId: currentUserId,
                                  receiverId: user.id,
                                );

                                Navigator.pop(dialogContext);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Friend request sent!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(ErrorHandler.getErrorMessage(e)),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
                  )
                else if (searchController.text.isNotEmpty)
                  const Text('No users found', style: TextStyle(color: kMuted)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: kText)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMethodCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.25)),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: kMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Color.fromARGB(255, 250, 251, 252)),
          ],
        ),
      ),
    );
  }

  // TAB 3: REQUESTS
  Widget _buildRequestsTab(String currentUserId) {
    return StreamBuilder<List<FriendRequest>>(
      stream: _friendService.getIncomingRequests(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final receivedRequests = snapshot.data ?? [];

        if (receivedRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                const Text('No friend requests',
                    style: TextStyle(fontSize: 16, color: kMuted)),
                const SizedBox(height: 8),
                const Text('You\'re all caught up! 🎉',
                    style: TextStyle(fontSize: 14, color: kMuted)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Text(
                  'Received',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kText,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${receivedRequests.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...receivedRequests.asMap().entries.map((entry) {
              final index = entry.key;
              final request = entry.value;
              return _buildReceivedRequestCard(request, currentUserId)
                  .animate()
                  .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                  .slideX(begin: -0.2, delay: (50 * index).ms);
            }),
          ],
        );
      },
    );
  }

  Widget _buildReceivedRequestCard(
      FriendRequest request, String currentUserId) {
    return FutureBuilder<app_user.User?>(
      future: _getSenderInfo(request.fromUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final sender = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: kPrimary,
                    child: Text(
                      sender.initials,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sender.email,
                          style: const TextStyle(fontSize: 13, color: kMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sent ${request.timeAgoText}',
                style: const TextStyle(fontSize: 12, color: kMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptRequest(request.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineRequest(request.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kText,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: kBorder),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<app_user.User?> _getSenderInfo(String senderId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(senderId).get();

      if (doc.exists) {
        return app_user.User.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      Logger.error('Failed to get sender info', e);
    }
    return null;
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await _friendService.acceptFriendRequest(requestId);
      _loadFriends();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(String requestId) async {
    try {
      await _friendService.declineFriendRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request declined'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
