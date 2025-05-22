import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://flutter-lab.onrender.com';

Future<void> showUserDialog({
  required BuildContext context,
  required bool isEditing,
  String? userId,
  required VoidCallback onSuccess,
}) async {
  final formKey = GlobalKey<FormState>();

  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();

  if (isEditing && userId != null) {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/getuser/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': userId}),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        firstnameController.text = data['firstname'] ?? '';
        lastnameController.text = data['lastname'] ?? '';
        emailController.text = data['email'] ?? '';
        passwordController.text = data['password'] ?? '';
        balanceController.text = data['balance'].toString();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  await showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: Text(isEditing ? 'Edit User' : 'Add User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstnameController,
                    decoration: InputDecoration(labelText: 'First Name'),
                    validator:
                        (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: lastnameController,
                    decoration: InputDecoration(labelText: 'Last Name'),
                    validator:
                        (val) => val == null || val.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      return emailRegex.hasMatch(val) ? null : 'Invalid email';
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Password'),
                    validator:
                        (val) =>
                            !isEditing && (val == null || val.isEmpty)
                                ? 'Required'
                                : null,
                  ),
                  TextFormField(
                    controller: balanceController,
                    decoration: InputDecoration(labelText: 'Balance'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final payload = {
                  "firstname": firstnameController.text.trim(),
                  "lastname": lastnameController.text.trim(),
                  "email": emailController.text.trim(),
                  "password": passwordController.text.trim(),
                  "imageurl": "https://example.com/image.jpg",
                  "balance":
                      double.tryParse(balanceController.text.trim()) ?? 0.0,
                };

                final uri =
                    isEditing
                        ? Uri.parse('$baseUrl/api/updateuser/')
                        : Uri.parse('$baseUrl/api/adduser/');

                final method = isEditing ? 'PUT' : 'POST';

                if (isEditing && userId != null) {
                  payload['id'] = userId;
                }

                try {
                  final request =
                      http.Request(method, uri)
                        ..headers['Content-Type'] = 'application/json'
                        ..body = jsonEncode(payload);

                  final streamedRes = await request.send();
                  final body = await streamedRes.stream.bytesToString();
                  debugPrint('Response: $body');

                  if (streamedRes.statusCode == 200 ||
                      streamedRes.statusCode == 201) {
                    Navigator.pop(context); // Close the form dialog
                    showSuccessDialog(
                      context,
                      isEditing
                          ? 'User updated successfully'
                          : 'User added successfully',
                    );
                    onSuccess(); // Refresh the user list
                  } else {
                    debugPrint('Error: ${streamedRes.statusCode}');
                  }
                } catch (e) {
                  debugPrint('Error saving user: $e');
                }
              },
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
  );
}

void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
  );
}
