class DataAssetsModel {
  List<String> assetsToken;
  DataAssetsModel({this.assetsToken});
  DataAssetsModel.fromJson(Map<String, dynamic> json) {
    assetsToken = json["assetsToken"];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["assetsToken"] = assetsToken;
    return data;
  }
}

class PayLoad {
  PayLoad({this.ver, this.base64, this.nameImage});
  num ver;
  String nameImage;
  String base64;
  PayLoad.fromJson(Map<String, dynamic> json) {
    ver = json['ver'];
    nameImage = json["NameImage"];
    base64 = json["Base64"];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["ver"] = ver;
    data["NameImage"] = nameImage;
    data["base64"] = base64;
    return data;
  }
}
