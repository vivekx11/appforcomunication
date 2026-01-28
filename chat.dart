import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatelessWidget {
  final String channel;
  ChatPage({super.key, required this.channel});

  final TextEditingController msgCtrl = TextEditingController();

  void sendMessage(String text) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(channel)
        .collection('messages')
        .add({'text': text, 'time': DateTime.now()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(channel)
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) =>
                      ListTile(title: Text(docs[i]['text'])),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  decoration: InputDecoration(hintText: "Type message"),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {
                  if (msgCtrl.text.isNotEmpty) {
                    sendMessage(msgCtrl.text);
                    msgCtrl.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
