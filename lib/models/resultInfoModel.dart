// -> 사용
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

ResultInfo resultInfoFromJson(String str) =>
    ResultInfo.fromJson(json.decode(str));

String resultInfoToJson(ResultInfo data) => json.encode(data.toJson());

class ResultInfo {
  ResultInfo({required this.success, required this.data, 
      /*  required this.userId,
    required this.krName,
    */ //required this.t,
      });

  bool success;
  Map<String, dynamic> data = {};
  
/*   int userId;
  String krName; */

  //int t;

  factory ResultInfo.fromJson(Map<String, dynamic> json) => ResultInfo(
      success: json["success"], data: json["data"],
      /*      userId: json["userId"],
        krName: json["krName"],
    */

      //t: json["t"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data,
         
/*         "userId": userId,
        "krName": krName,         */
        //"t": t,
      };
}
