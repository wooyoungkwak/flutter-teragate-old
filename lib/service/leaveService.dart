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

// 퇴근
leave(id,ip) async {
  print("#################퇴근##################");
  Map<String, String> param = {"user_id": id,"att_ip_out":ip};

  var url =
      Uri.parse("${Env.URL_PREFIX}/leave").replace(queryParameters: param);
  final response = await http.get(url);
  print("###########################");
  print(response);
  if (response.statusCode == 200) {
    return ResultInfo.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load album');
  }
}
