// ============================================
// FILE: lib/screens/collaborators_page.dart
// ============================================

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/friend_request.dart';
import '../../data/mock_users.dart';
import '../../data/mock_friend_requests.dart';

class CollaboratorsPage extends StatefulWidget {
  const CollaboratorsPage({Key? key}) : super(key: key);

  @override
  State<CollaboratorsPage> createState() => _CollaboratorsPageState();
}

class _CollaboratorsPageState extends State<CollaboratorsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<User> _allFriends = [];
  List<User> _filteredFriends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _receivedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Ensures suffixIcon (clear button) refreshes when text changes.
    _searchController.addListener(() {
      setState(() {});
    });

    _loadData();
  }

  void _loadData() {
    setState(() {
      _allFriends = MockUsers.getFriends();
      _filteredFriends = List<User>.from(_allFriends);
      _pendingRequests = MockFriendRequests.getPendingRequests();
      _receivedRequests = MockFriendRequests.getReceivedRequests();
    });
  }

  void _searchFriends(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredFriends = List<User>.from(_allFriends);
        return;
      }

      // Filter based on current list (so removed friends stay removed).
      _filteredFriends = _allFriends.where((u) {
        final name = u.name.toLowerCase();
        final email = u.email.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    });
  }

  void _removeFriend(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allFriends.removeWhere((f) => f.id == user.id);
                _filteredFriends.removeWhere((f) => f.id == user.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} removed'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _cancelRequest(FriendRequest request) {
    setState(() {
      _pendingRequests.removeWhere((r) => r.id == request.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend request cancelled'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _acceptRequest(FriendRequest request) {
    setState(() {
      _receivedRequests.removeWhere((r) => r.id == request.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You are now friends with ${MockFriendRequests.getUserName(request.fromUserId)}!',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _declineRequest(FriendRequest request) {
    setState(() {
      _receivedRequests.removeWhere((r) => r.id == request.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend request declined'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  void _showAddFriendOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add Collaborator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Add by Email
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _showAddByEmailDialog();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
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
                            'Add by Email',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Search IIUM email address',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
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
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple,
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
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan friend\'s QR code',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey[600])),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showMyQRCode();
              },
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Generate My QR Code'),
              style: OutlinedButton.styleFrom(
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

  void _showAddByEmailDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add by Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'IIUM Email',
                hintText: 'friend@iium.edu.my',
                prefixIcon: const Icon(Icons.email),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Friend request sent to ${emailController.text}'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Scanner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'QR Scanner\nComing Soon!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMyQRCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.qr_code_2, size: 120, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    MockUsers.currentUser.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MockUsers.currentUser.email,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask your friend to scan this code',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
    final totalRequests = _pendingRequests.length + _receivedRequests.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Collaborators',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF2196F3)),
            onPressed: _showAddFriendOptions,
            tooltip: 'Add Friend',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          tabs: [
            const Tab(text: 'My Team'),
            const Tab(text: 'Add Friend'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  if (totalRequests > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      child: Text(
                        '$totalRequests',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTeamTab(),
          _buildAddFriendTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  // TAB 1: MY TEAM
  Widget _buildMyTeamTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchFriends('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
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
                'My Team (${_filteredFriends.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
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
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No friends yet'
                            : 'No friends found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Tap + to add your first teammate!'
                            : 'Try a different search',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = _filteredFriends[index];
                    return _buildFriendCard(friend);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(User friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2196F3),
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
                      border: Border.all(color: Colors.white, width: 2),
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
                    color: Color(0xFF1A1A2E),
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            onSelected: (value) {
              if (value == 'remove') {
                _removeFriend(friend);
              } else if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile coming soon!')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('View Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
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

  // TAB 2: ADD FRIEND
  Widget _buildAddFriendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add New Collaborator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you want to add a friend',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildAddMethodCard(
            icon: Icons.email,
            iconColor: Colors.blue,
            title: 'Add by Email',
            description: 'Search and invite by IIUM email address',
            onTap: _showAddByEmailDialog,
          ),
          const SizedBox(height: 16),
          _buildAddMethodCard(
            icon: Icons.qr_code_scanner,
            iconColor: Colors.purple,
            title: 'Scan QR Code',
            description: 'Scan your friend\'s QR code to connect instantly',
            onTap: _showQRScanner,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: Colors.grey[600])),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 64, color: Color(0xFF2196F3)),
                const SizedBox(height: 16),
                const Text(
                  'Share Your QR Code',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let others scan your unique QR code',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showMyQRCode,
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Show My QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // TAB 3: REQUESTS
  Widget _buildRequestsTab() {
    final hasPending = _pendingRequests.isNotEmpty;
    final hasReceived = _receivedRequests.isNotEmpty;

    if (!hasPending && !hasReceived) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No friend requests',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('You\'re all caught up! 🎉',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (hasReceived) ...[
          Row(
            children: [
              const Text(
                'Received',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.red, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${_receivedRequests.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._receivedRequests.map(_buildReceivedRequestCard),
          const SizedBox(height: 24),
        ],
        if (hasPending) ...[
          Row(
            children: [
              const Text(
                'Pending',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${_pendingRequests.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingRequests.map(_buildPendingRequestCard),
        ],
      ],
    );
  }

  // FIXED: RECEIVED REQUEST CARD
  Widget _buildReceivedRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF2196F3),
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MockFriendRequests.getUserName(request.fromUserId),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MockFriendRequests.getUserEmail(request.fromUserId),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sent ${request.timeAgoText}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
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
                  onPressed: () => _declineRequest(request),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIXED: PENDING REQUEST CARD
  Widget _buildPendingRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.orange,
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockFriendRequests.getUserName(request.toUserId),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  MockFriendRequests.getUserEmail(request.toUserId),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sent ${request.timeAgoText}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _cancelRequest(request),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Cancel',
          ),
        ],
      ),
    );
  }
}
