import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:tera_gate_app/screens/bluetooth.dart';

// flutterBlue
FlutterBlue flutterBlue = FlutterBlue.instance;

// 연결 상태 표시 문자열
String stateText = 'Connecting';

// 연결 아이콘
bool stateConnect = true;

// 현재 연결 상태 저장용
BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

// 연결 상태 리스너 핸들 화면 종료시 리스너 해제를 위함
StreamSubscription<BluetoothDeviceState>? _stateListener;

/* 연결 상태 갱신 */
setBleConnectionState(BluetoothDeviceState event) {
  switch (event) {
    case BluetoothDeviceState.disconnected:
      stateText = '연결해제';
      // 버튼 상태 변경
      stateConnect = false;
      break;
    case BluetoothDeviceState.disconnecting:
      stateText = '연결해제중';
      break;
    case BluetoothDeviceState.connected:
      stateText = '연결됨';
      // 버튼 상태 변경
      stateConnect = true;
      break;
    case BluetoothDeviceState.connecting:
      stateText = '연결중';
      break;
  }
  //이전 상태 이벤트 저장
  deviceState = event;
  //return {stateText: stateText, connectIcon: connectIcon};
  return [stateText, stateConnect];
}
