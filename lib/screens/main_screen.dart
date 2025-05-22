import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lab3/screens/dialog.dart';
import 'dart:convert';

import 'package:lab3/screens/usercard.dart';

class UserPortal extends StatefulWidget {
  const UserPortal({super.key});

  @override
  State<UserPortal> createState() => _UserPortalState();
}

class _UserPortalState extends State<UserPortal> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  String baseUrl = 'https://flutter-lab.onrender.com';

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/getusers/'));
      debugPrint('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Fetched users: $data');

        setState(() {
          users = data;
          isLoading = false;
        });
      } else {
        debugPrint('Failed to load users.');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
              ? const Center(child: Text('No users found.'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ...users.map(
                      (user) => UserCard(
                        user: user,
                        onEdit: () {
                          showUserDialog(
                            context: context,
                            isEditing: true,
                            userId: user['id'].toString(),
                            onSuccess: fetchUsers,
                          );
                        },
                        onDelete: () async {
                          final response = await http.delete(
                            Uri.parse(('$baseUrl/api/deleteuser/')),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'id': user['id']}),
                          );
                          if (response.statusCode == 200) {
                            debugPrint('Deleted user ${user['id']}');
                            fetchUsers();
                          } else {
                            debugPrint('Failed to delete user');
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showUserDialog(
                            context: context,
                            isEditing: false,
                            onSuccess: fetchUsers,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
