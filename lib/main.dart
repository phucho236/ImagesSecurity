import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:images_security/login_page.dart';
import 'package:images_security/profile_user_provider.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ProfileUserProvider()),
            ],
            child: MaterialApp(
              home: snapshot.hasError
                  ? Scaffold(
                      body: Center(
                        child: Text(snapshot.hasError.toString()),
                      ),
                    )
                  : snapshot.connectionState == ConnectionState.done
                      ? LoginPage()
                      : Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
            ),
          );
        });
  }
}
