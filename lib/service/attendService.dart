import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:tera_gate_app/models/attendinfo.dart';

import '../env.dart';

import 'package:tera_gate_app/models/resultInfoModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tera_gate_app/utils/loginStatus.dart';
import 'package:tera_gate_app/models/keyModel.dart';
import 'package:tera_gate_app/models/attendinfo.dart';

// key DB 가져오기
keyCheck(attend_key) async {
  var url = Uri.parse("${Env.URL_PREFIX}/keyCheck");
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final result = utf8.decode(response.bodyBytes);
    Map<String, dynamic> keyMap = jsonDecode(result);
    var cheak_key = keyinfo.fromJson(keyMap);

    return '${cheak_key.commute_key}';
  } else {
    throw Exception('Failed to load album');
  }
}

// 출근
attend(id, ip) async {
  print("#################출근##################");
  Map<String, String> param = {"user_id": id, "att_ip_in": ip};
  print(param);
  var url =
      Uri.parse("http://192.168.0.164:3000/groupware/ajax_attend_user_v3");
  var data = {"userId": id, "attIpIn": ip};
  var body = json.encode(data);
  var response = await http.post(url,
      headers: {"Content-Type": "application/json"}, body: body);

  print(response.body);
  if (response.statusCode == 200) {
    return "TEST";
  } else {
    throw Exception('Failed to load album');
  }
}

//user_id 가져오기
/* attendidCheck() async {
  print("############유저id#############");
  const flutterSecureStorage = FlutterSecureStorage();
  debugPrint('autulogin :${await flutterSecureStorage.readAll()}');
  Map<String, String> allStorage = await flutterSecureStorage.readAll();
  String statusUser = '';
  String loginId = '';
  String loginPw = '';
  if (allStorage.isNotEmpty) {
    allStorage.forEach((k, v) {
      debugPrint('k : $k, v : $v');
      if (v == STATUS_LOGIN) statusUser = k;

      if (k == 'LOGIN_ID') loginId = v;
      if (k == 'LOGIN_PW') loginPw = v;
    });
  }

  Map<String, String> param = {
    "loginId": loginId,
    "password": loginPw,
  };

  var url =
      Uri.parse("${Env.URL_PREFIX}/attendid").replace(queryParameters: param);
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print("#########################RESPONSE");
    debugPrint("body:" + response.body);

    return response;
  } else {
    throw Exception('Failed to load album');
  }
}
 */

//출근 중복체크
attendoverlapCheck(id) async {
  print("#################출근중복체크##################");
  Map<String, String> param = {"user_id": id};
  var url =
      //Uri.parse("${Env.URL_PREFIX}/groupware/ajax_get_today_my_attend_data_v3")
      Uri.parse(
              "http://http://192.168.0.164:3000/getTdyMyAtndData")
          .replace(queryParameters: param);
  var response = await http.get(url);
  if (response.statusCode == 200) {
    print(response.body);
    return ResultInfo.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}
