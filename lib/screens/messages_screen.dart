import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MessagesScreen extends StatefulWidget {
  final String userId;
  final String profileName;
  final String accessToken;
  final String igUserId;

  const MessagesScreen({
    required this.userId,
    required this.profileName,
    required this.accessToken,
    required this.igUserId,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List messages = [];
  bool _loading = true;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    final url = Uri.parse(
      'https://5000-shivam63982-instamanage-avo1ivrmwxi.ws-us120.gitpod.io/fetch_messages/${widget.userId}'
      '?access_token=${Uri.encodeComponent(widget.accessToken)}'
      '&ig_user_id=${Uri.encodeComponent(widget.igUserId)}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data;
          _loading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      } else {
        throw Exception("Failed to load messages");
      }
    } catch (e) {
      print("❌ Error loading messages: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading messages")),
      );
      setState(() => _loading = false);
    }
  }

  Widget buildMessage(Map msg) {
    final isFromYou = msg["sender"] == "user";

    return Align(
      alignment: isFromYou ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isFromYou ? Colors.indigo.shade400 : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isFromYou ? Radius.circular(16) : Radius.circular(0),
            bottomRight: isFromYou ? Radius.circular(0) : Radius.circular(16),
          ),
        ),
        child: Text(
          msg["text"] ?? '',
          style: TextStyle(
            color: isFromYou ? Colors.white : Colors.black,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    print("📤 Sending message: $text");

    setState(() {
      messages.add({
        "text": text,
        "sender": "user",
        "timestamp": DateTime.now().toIso8601String(),
      });
    });

    _controller.clear();

    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profileName),
        backgroundColor: Colors.indigo,
      ),
      backgroundColor: Colors.indigo.shade50,
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text("No messages found"))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return buildMessage(messages[index]);
                        },
                      ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
