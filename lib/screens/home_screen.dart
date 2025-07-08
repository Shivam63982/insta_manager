import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String accessToken;
  final String igUserId;

  const HomeScreen({
    required this.accessToken,
    required this.igUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Text(
          "Welcome IG User ID:\n$igUserId",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
