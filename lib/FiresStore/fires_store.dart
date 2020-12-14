import 'package:cloud_firestore/cloud_firestore.dart';

class FiresStore {
  Future<bool> pushAssetsToken(String googleID, List<String> assets) async {
    Map<String, dynamic> data = Map<String, dynamic>();
    data["AssetsToken"] = FieldValue.arrayUnion(assets);
    await FirebaseFirestore.instance
        .collection(googleID)
        .doc("AssetsToken")
        .update(data)
        .catchError((err) {
      return false;
    });
    return true;
  }

  Future<bool> checkAcount(String googleID) async {
    bool a = await FirebaseFirestore.instance
        .collection(googleID)
        .get()
        .then((value) {
      if (value.docs.length > 0) {
        return true;
      }
      return false;
    });
    return a;
  }

  Future<bool> createAcount(String googleID) async {
    Map<String, dynamic> data = Map<String, dynamic>();
    data["AssetsToken"] = [];
    await FirebaseFirestore.instance
        .collection(googleID)
        .doc("AssetsToken")
        .set(data)
        .catchError((err) {
      return false;
    });
    return true;
  }

  Future<List<dynamic>> getAssetsToken(String googleID) async {
    List<dynamic> rp = [];
    await FirebaseFirestore.instance
        .collection(googleID)
        .doc("AssetsToken")
        .get()
        .then((value) async {
      print(value.data()["AssetsToken"]);
      rp = value.data()["AssetsToken"];
    });
    return rp;
  }
}
