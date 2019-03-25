import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_fb_tutorial/const.dart';
import 'package:flutter_fb_tutorial/main.dart';

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Tutorial',
      theme: ThemeData(
        primaryColor: themeColor
      ),
      home: LoginScreen(title: 'CHAT TUTORIAL'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String title;

  LoginScreen({Key key, this.title}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    SharedPreferences.setMockInitialValues({});

    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() => isLoading = true );

    this.prefs = await SharedPreferences.getInstance();

    this.isLoggedIn = await googleSignIn.isSignedIn();
    if(this.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(currentUserId: prefs.getString('id')))
      );
    }

    this.setState(() => isLoading = false);
  }

  Future<Null> handleSignIn() async {
    this.prefs = await SharedPreferences.getInstance();

    this.setState(() => isLoading = true);

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

    FirebaseUser firebaseUser = await firebaseAuth.signInWithCredential(credential);

    if(firebaseUser != null) {
      final QuerySnapshot result = await Firestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length == 0) {
        Firestore.instance.collection('users').document(firebaseUser.uid).setData({'nickname': firebaseUser.displayName, 'photoUrl': firebaseUser.photoUrl, 'id': firebaseUser.uid});

        this.currentUser = firebaseUser;
        await this.prefs.setString('id', this.currentUser.uid);
        await this.prefs.setString('nickname', this.currentUser.displayName);
        await this.prefs.setString('photoUrl', this.currentUser.photoUrl);
      } else {
        await this.prefs.setString('id', documents[0]['id']);
        await this.prefs.setString('nickname', documents[0]['nickname']);
        await this.prefs.setString('photoUrl', documents[0]['photoUrl']);
        await this.prefs.setString('aboutMe', documents[0]['aboutMe']);
      }
      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() => isLoading = false);

      Navigator.push(context, MaterialPageRoute(builder: (context) => MainScreen(currentUserId: firebaseUser.uid)));
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: FlatButton(
              onPressed: handleSignIn,
              child: Text(
                'SIGN IN WITH GOOGLE',
                style: TextStyle(fontSize: 16.0)
              ),
              color: Color(0xffdd4b39),
              highlightColor: Color(0xffff7f7f),
              splashColor: Colors.transparent,
              textColor: Colors.white,
              padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
            ),

            Positioned(
              child: isLoading
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor)
                      )
                    ),
                    color: Colors.white.withOpacity(0.8),
                ) : Container()
            )
        ]
      )
    );
  }
}

