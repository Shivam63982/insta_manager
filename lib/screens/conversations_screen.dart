import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'messages_screen.dart'; // 👈 make sure this import is there

class ConversationsScreen extends StatefulWidget {
  final String accessToken;
  final String igUserId;

  const ConversationsScreen({
    required this.accessToken,
    required this.igUserId,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final url = Uri.parse(
      'https://5000-shivam63982-instamanage-avo1ivrmwxi.ws-us120.gitpod.io/conversations'
      '?access_token=${Uri.encodeComponent(widget.accessToken)}'
      '&ig_user_id=${Uri.encodeComponent(widget.igUserId)}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          users = data.values.toList(); // user ID keys → list of user objects
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load known users");
      }
    } catch (e) {
      print("❌ Error fetching known users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading conversation list")),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversations"),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.indigo.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text("No conversations found"))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final name = user["name"] ?? "";
                    final username = user["username"] ?? "";
                    final profilePic = user["profile_pic"] ?? "";

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : null,
                          child: profilePic.isEmpty
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                          backgroundColor: Colors.indigo.shade300,
                        ),
                        title: Text(name.isNotEmpty ? name : username),
                        subtitle: name.isNotEmpty ? Text('@$username') : null,
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MessagesScreen(
        userId: user["id"],
        profileName: user["username"],
        accessToken: widget.accessToken,
        igUserId: widget.igUserId,
      ),
    ),
  );
}

                      ),
                    );
                  },
                ),
    );
  }
}
