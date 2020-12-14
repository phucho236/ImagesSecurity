import 'package:flutter/cupertino.dart';

class ProfileUserProvider extends ChangeNotifier {
  String profileUser;

  onUpdateProfileUser({String newValue}) {
    profileUser = newValue;
    notifyListeners();
  }
}
