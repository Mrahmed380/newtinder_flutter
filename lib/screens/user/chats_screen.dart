import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newtinder/widgets/chat/chat_list_tile.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  CollectionReference chatsDb = FirebaseFirestore.instance.collection('chats');
  User user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: chatsDb.where('members', arrayContains: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> chats = snapshot.data.docs.toList();
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              return ChatListTile(
                data: chats,
                user: user,
                index: index,
              );
            },
          );
        }
        return Material(child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}