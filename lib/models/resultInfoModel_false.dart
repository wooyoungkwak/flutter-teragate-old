// -> 사용
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

ResultInfo_false resultInfoFromJson(String str) =>
    ResultInfo_false.fromJson(json.decode(str));

String resultInfoToJson(ResultInfo_false data) => json.encode(data.toJson());

class ResultInfo_false {
  ResultInfo_false({required this.success, required this.message
      /*  required this.userId,
    required this.krName,
    */ //required this.t,
      });

  bool success;
  String message;
/*   int userId;
  String krName; */

  //int t;

  factory ResultInfo_false.fromJson(Map<String, dynamic> json) => ResultInfo_false(
      success: json["success"], message: json["message"]
      /*      userId: json["userId"],
        krName: json["krName"],
    */

      //t: json["t"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
         "message": message
/*         "userId": userId,
        "krName": krName,         */
        //"t": t,
      };
}
