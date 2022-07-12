import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:tera_gate_app/models/resultInfoModel_false.dart';

import '../env.dart';

import 'package:tera_gate_app/models/resultInfoModel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tera_gate_app/utils/loginStatus.dart';
import 'dart:async';

Map<String, String> headers = {};

void updateCookie(http.Response response) {
  String? rawCookie = response.headers['connect.sid'];
  print(rawCookie);
  if (rawCookie != null) {
    int index = rawCookie.indexOf(';');
    headers['cookie'] =
        (index == -1) ? rawCookie : rawCookie.substring(0, index);
  }
}

// 로그인체크
loginCheck(loginId, password) async {
  const flutterSecureStorage = FlutterSecureStorage();
/*   Map<String, String> param = {
    "loginId": loginId,
    "password": password,
  }; */

  var data = {"loginId": loginId, "password": password};
  var body = json.encode(data);

  String id = loginId;
  String pw = password;

  //var url = Uri.parse("http://teraenergy.iptime.org:3000/login").replace(queryParameters: param);
  var url = Uri.parse("http://192.168.0.164:3000/login");
  //String url = 'http://teraenergy.iptime.org:3000/login';
  //final response = await http.get(url){
  var response = await http.post(url,
      headers: {"Content-Type": "application/json"}, body: body);
  if (response.statusCode == 200) {
    flutterSecureStorage.deleteAll();
    flutterSecureStorage.write(key: id, value: pw);
    flutterSecureStorage.write(key: LOGIN_ID, value: id);
    flutterSecureStorage.write(key: LOGIN_PW, value: pw);
    flutterSecureStorage.write(key: '${id}_$pw', value: USER_NICK_NAME);
    flutterSecureStorage.write(key: USER_NICK_NAME, value: STATUS_LOGIN);

    var result = utf8.decode(response.bodyBytes);
    Map<String, dynamic> keyMap = jsonDecode(result);
    var userinfo;

    if (keyMap.values.first) {
      //로그인 성공 실패 체크해서 Model 다르게 설정
       userinfo = ResultInfo.fromJson(keyMap);
    } else {
       userinfo = ResultInfo_false.fromJson(keyMap);
    }
    print(userinfo);
    if (userinfo.success) {
      flutterSecureStorage.write(
          key: 'user_id', value: '${userinfo.data['userId']}');
      flutterSecureStorage.write(
          key: 'kr_name', value: '${userinfo.data['krName']}');
              updateCookie(response);
    return ResultInfo.fromJson(json.decode(response.body));
    } else {
      flutterSecureStorage.write(key: 'user_id', value: "0000");
      flutterSecureStorage.write(key: 'kr_name', value: 'noname');
          updateCookie(response);
    return ResultInfo_false.fromJson(json.decode(response.body));
    }

  } else {
    throw Exception('Failed to load album');
  }
}
