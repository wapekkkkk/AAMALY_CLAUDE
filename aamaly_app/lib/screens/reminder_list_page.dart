// ============================================
// FILE: lib/screens/reminder_list_page.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../data/mock_reminders.dart';
import 'create_reminder_page.dart';

class ReminderListPage extends StatefulWidget {
  const ReminderListPage({Key? key}) : super(key: key);

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _reminders = MockReminders.getReminders();
  }

  void _toggleReminder(Reminder reminder) {
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder.copyWith(isActive: !reminder.isActive);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reminder.isActive ? 'Reminder turned off' : 'Reminder turned on',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteReminder(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _reminders.removeWhere((r) => r.id == reminder.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
      ),
      body: _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first reminder',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return _buildReminderCard(reminder);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newReminder = await Navigator.push<Reminder>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateReminderPage(),
            ),
          );

          if (newReminder != null) {
            setState(() {
              _reminders.insert(0, newReminder);
            });
          }
        },
        backgroundColor: const Color(0xFF7B68EE),
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    Color frequencyColor;
    IconData frequencyIcon;

    switch (reminder.frequency) {
      case ReminderFrequency.once:
        frequencyColor = Colors.blue;
        frequencyIcon = Icons.event;
        break;
      case ReminderFrequency.daily:
        frequencyColor = Colors.green;
        frequencyIcon = Icons.today;
        break;
      case ReminderFrequency.weekly:
        frequencyColor = Colors.orange;
        frequencyIcon = Icons.calendar_view_week;
        break;
      case ReminderFrequency.monthly:
        frequencyColor = Colors.purple;
        frequencyIcon = Icons.calendar_month;
        break;
    }

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
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7B68EE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.alarm,
              color: const Color(0xFF7B68EE),
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(frequencyIcon, size: 14, color: frequencyColor),
                    const SizedBox(width: 4),
                    Text(
                      reminder.frequency
                          .toString()
                          .split('.')
                          .last
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: frequencyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(reminder.reminderTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: reminder.isActive,
            onChanged: (value) => _toggleReminder(reminder),
            activeColor: const Color(0xFF7B68EE),
          ),

          // Menu
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit coming soon!')),
                );
              } else if (value == 'delete') {
                _deleteReminder(reminder);
              }
            },
          ),
        ],
      ),
    );
  }
}
