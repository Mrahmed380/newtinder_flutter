import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:newtinder/widgets/chat/chat_message_bubble.dart';
import 'package:newtinder/widgets/chat/message_input_field.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatPartnerUid;

  const ChatScreen({
    Key key,
    this.chatId,
    this.chatPartnerUid,
  }) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  CollectionReference usersDb = FirebaseFirestore.instance.collection('users');
  CollectionReference chatsDb = FirebaseFirestore.instance.collection('chats');
  ScrollController messagesController = ScrollController();
  TextEditingController messageController = TextEditingController();
  bool showScrollDownButton = true;
  User user = FirebaseAuth.instance.currentUser;
  String chatPartnerImage = 'https://i.gifer.com/VLGA.gif';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: chatsDb
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> messages = snapshot.data.docs.toList();
          if (chatPartnerImage == 'https://i.gifer.com/VLGA.gif') {
            fetchChatPartnerImage();
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.redAccent,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              centerTitle: true,
              title: Text(
                'Team Tinder',
                style: TextStyle(color: Colors.black),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.redAccent),
                  onPressed: () {},
                ),
              ],
            ),
            floatingActionButton: Visibility(
              visible: showScrollDownButton,
              child: Padding(
                padding: EdgeInsets.only(bottom: 35),
                child: FloatingActionButton(
                  mini: true,
                  elevation: 2,
                  backgroundColor: Colors.white,
                  child: Transform.rotate(
                    angle: 270 * pi / 180,
                    child: SvgPicture.asset(
                      'assets/icons/back.svg',
                      height: 20,
                      color: Colors.blueGrey.shade200,
                    ),
                  ),
                  onPressed: () {
                    messagesController
                        .jumpTo(messagesController.position.minScrollExtent);
                  },
                ),
              ),
            ),
            body: Column(
              children: [
                Flexible(
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      setState(() {
                        showScrollDownButton = notification.metrics.pixels > 25;
                      });
                      return null;
                    },
                    child: ListView.builder(
                      reverse: true,
                      controller: messagesController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessageBubble(
                          index: index,
                          messages: messages,
                          user: user,
                          chatPartnerImage: chatPartnerImage,
                        );
                      },
                    ),
                  ),
                ),
                MessageInputField(
                  messageController: messageController,
                  sendMessage: sendMessage,
                ),
              ],
            ),
          );
        }
        return Material(child: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Future<void> fetchChatPartnerImage() async {
    DocumentSnapshot chatPartnerData =
        await usersDb.doc(widget.chatPartnerUid).get();
    setState(() {
      chatPartnerImage = chatPartnerData.data()['profilePic'];
    });
  }

  Future<void> sendMessage() async {
    messageController.text;
    chatsDb.doc(widget.chatId).collection('messages').add({
      'message': messageController.text,
      'sender': user.uid,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }
}