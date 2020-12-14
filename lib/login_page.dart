import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:images_security/FiresStore/fires_store.dart';
import 'package:images_security/home_page.dart';
import 'package:images_security/profile_user_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FiresStore firesStore = new FiresStore();
  double width = 60.0;
  double widthScreen;
  double heightScreen;
  bool onClickButton = false;
  bool isLoading = false;
  bool onDone = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      widthScreen = MediaQuery.of(context).size.width;
      heightScreen = MediaQuery.of(context).size.height;
    });

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          isLoading
              ? Container(
                  padding: EdgeInsets.all(10),
                  decoration: new BoxDecoration(
                    color: const Color.fromRGBO(247, 64, 106, 1.0),
                    borderRadius:
                        new BorderRadius.all(const Radius.circular(40.0)),
                  ),
                  child: Container(
                    decoration: new BoxDecoration(
                        borderRadius:
                            new BorderRadius.all(const Radius.circular(30.0)),
                        image: DecorationImage(
                          image:
                              new AssetImage("assets/images/google-icon.gif"),
                          fit: BoxFit.cover,
                        )),
                    height: 40,
                    width: 40,
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    signInWithGoogle().then((value) {
                      if (value != null) {
                        setState(() {
                          onClickButton = true;
                        });
                        Future.delayed(Duration(seconds: 1), () {
                          setState(() {
                            isLoading = true;
                          });
                        });
                        Future.delayed(Duration(seconds: 7), () {
                          setState(() {
                            isLoading = false;
                          });
                        });
                        Future.delayed(Duration(milliseconds: 7500), () {
                          setState(() {
                            onDone = true;
                          });
                        });
                        Future.delayed(Duration(milliseconds: 9000), () {
                          return true;
                        }).then((value) {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (c, a1, a2) => HomePage(),
                              transitionsBuilder: (c, anim, a2, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration: Duration(milliseconds: 1500),
                            ),
                          );
                        });
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(seconds: onDone ? 1 : 1),
                    curve: onDone ? Curves.slowMiddle : Curves.slowMiddle,
                    width: onDone
                        ? widthScreen
                        : onClickButton
                            ? width
                            : 320.0,
                    height: onDone ? heightScreen : 60.0,
                    alignment: FractionalOffset.center,
                    decoration: new BoxDecoration(
                      color: const Color.fromRGBO(247, 64, 106, 1.0),
                      borderRadius: BorderRadius.all(
                          onDone ? Radius.circular(0) : Radius.circular(30.0)),
                    ),
                    child: new Text(
                      onClickButton ? "" : "Sign In With Google",
                      style: new TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                )
        ],
      ),
    );
  }

  Future<String> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    assert(!userCredential.user.isAnonymous);
    assert(await userCredential.user.getIdToken() != null);
    firesStore.checkAcount(userCredential.user.uid).then((value) {
      print(value);
      if (value == false) firesStore.createAcount(userCredential.user.uid);
    });
    Provider.of<ProfileUserProvider>(context, listen: false)
        .onUpdateProfileUser(newValue: userCredential.user.uid);
    return 'signInWithGoogle succeeded: ${userCredential.user.email}';
  }
}
