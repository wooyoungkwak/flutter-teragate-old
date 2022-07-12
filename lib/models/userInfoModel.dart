// -> 사용
import 'dart:convert';

UserInfo userInfoFromJson(String str) => UserInfo.fromJson(json.decode(str));

String userInfoInfoToJson(UserInfo data) => json.encode(data.toJson());

class UserInfo {
  UserInfo({
    required this.success,
    required this.info,
  });

  bool success;
  Info info;

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        success: json["success"],
        info: Info.fromJson(json["info"]),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "info": info.toJson(),
      };
}

class Info {
  Info({
    required this.loginId,
    required this.password,
  });

  String loginId;
  String password;

  factory Info.fromJson(Map<String, dynamic> json) => Info(
        loginId: json["userId"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "loginId": loginId,
        "password": password,
      };
}
