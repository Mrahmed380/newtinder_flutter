import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newtinder/card/swipeable_card.dart';
import 'package:newtinder/card/swipeable_widget.dart';
import 'package:newtinder/widgets/swipe/swipe_actions_row.dart';
import 'package:newtinder/widgets/swipe/swipe_section.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    Key key,
  }) : super(key: key);

  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

final List<SwipeableCard> cards = [];

class _SwipeScreenState extends State<SwipeScreen> {
  CollectionReference userDb = FirebaseFirestore.instance.collection("users");
  SwipeableWidgetController _cardController = SwipeableWidgetController();
  User user = FirebaseAuth.instance.currentUser;
  int currentCardIndex = 0;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: userDb.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Something went wrong");
        }
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> userData = snapshot.data.docs.toList();

          return SafeArea(
            child: Column(
              children: [
                SwipeSection(
                  userData: userData,
                  cardController: _cardController,
                  currentCardIndex: currentCardIndex,
                  swipeLeft: swipeLeft,
                  swipeRight: swipeRight,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: SwipeActionsRow(cardController: _cardController),
                )
              ],
            ),
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  void swipeLeft(uid) {
    print("card swiped to the left");
    print(uid);
    setState(() {
      currentCardIndex++;
    });
  }

  void swipeRight(uid) {
    print("card swiped to the right");
    userDb.doc(user.uid).update({
      'likes': FieldValue.arrayUnion([uid])
    });
    setState(() {
      currentCardIndex++;
    });
  }
}
