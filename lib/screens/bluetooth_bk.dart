import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:tera_gate_app/screens/login.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
//import 'package:tera_gate_app/screens/widgets/loader.dart';

import './device.dart';

class Bluetooth extends StatefulWidget {
  const Bluetooth({Key? key}) : super(key: key);

  @override
  _BluetoothState createState() => _BluetoothState();
}

class _BluetoothState extends State<Bluetooth> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResultList = [];
  late ProgressDialog progressDialog;
  // 현재 연결 상태 저장용
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;
  bool _isScanning = false;
  bool _isChecked = true;
  bool _isConnecting = true;

  @override
  initState() {
    super.initState();
    // 블루투스 초기화
    initBle();
  }

  void initBle() {
    // BLE 스캔 상태 얻기 위한 리스너
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });

    if (_isChecked) {
      scan();
    } else {
      flutterBlue.stopScan();
    }
  }

  void showProgress() async {
    String stateText = ''; //setBleConnectionState(deviceState);
    debugPrint(stateText);
    progressDialog.style(message: '연결중');
    progressDialog.show();
    if (_isConnecting) {
      progressDialog.update(message: '연결됨');
    } else {
      progressDialog.update(message: '연결되지않음');
    }
    Future.delayed(const Duration(seconds: 2)).then((value) {
      progressDialog.hide();
    });
  }

  late List result;
  bool check = false;
  String viewTxt = "대기중...";
  /*
  스캔 시작/정지 함수
  */
  Future scan() async {
    setState(() {
      check = true;
      viewTxt = "검색중...";
    });
    if (!_isScanning) {
      // 스캔 중이 아니라면
      // 기존에 스캔된 리스트 삭제
      scanResultList.clear();
      // 스캔 시작, 제한 시간 4초
      await flutterBlue
          .startScan(
              scanMode: ScanMode.balanced,
              allowDuplicates: true,
              timeout: const Duration(seconds: 12))
          .timeout(const Duration(seconds: 12), onTimeout: () async {
        await flutterBlue.stopScan();
        setState(() {
          check = false;
          viewTxt = "완료";
        });
      });
      // 스캔 결과 리스너
      flutterBlue.scanResults.listen((results) {
        // List<ScanResult> 형태의 results 값을 scanResultList에 복사
        scanResultList = results;
        result = results;
        // UI 갱신
        setState(() {});
      });
    } else {
      // 스캔 중이라면 스캔 정지
      scanStop();
    }
    return;
  }

  Future scanStop() async {
    setState(() {
      check = false;
      viewTxt = "종료중...";
    });
    await Future.delayed(const Duration(seconds: 13), () async {
      await flutterBlue.stopScan();
      setState(() {
        check = false;
        if (scanResultList.isEmpty) viewTxt = "대기중...";
      });
    });
  }

  /*
    여기서부터는 장치별 출력용 함수들
  */
  /* 장치의 MAC 주소 위젯  */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /* 장치의 명 위젯  */
  Widget deviceName(ScanResult r) {
    String name = '';

    if (r.device.name.isNotEmpty) {
      // device.name에 값이 있다면
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // advertisementData.localName에 값이 있다면
      name = r.advertisementData.localName;
    } else {
      // 둘다 없다면 이름 알 수 없음...
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE 아이콘 위젯 */
  Widget leading(ScanResult r) {
    return const CircleAvatar(
      child: Icon(
        Icons.bluetooth_connected,
        color: Colors.white,
      ),
      backgroundColor: Colors.cyan,
    );
  }

  /* 장치 아이템을 탭 했을때 호출 되는 함수 */
  void onTap(ScanResult r) async {
    flutterBlue.stopScan();
    // 단순히 이름만 출력
    debugPrint(r.device.name);
    progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: true, showLogs: true);
    showProgress();
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => Device(device: r.device)),
    // );
    //await r.device.connect();
  }

  /* 장치 아이템 위젯 */
  Widget listItem(ScanResult r) {
    const icon = Icons.bluetooth_disabled;
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: const Icon(icon),
    );
  }

  /* 스위치 버튼 위젯 */
  Widget bluetoothSwitch() {
    return SwitchListTile(
      title: const Text('Bluetooth'),
      value: _isChecked,
      onChanged: (value) {
        if (value) {
          scan();
        } else {
          scanResultList.clear();
          scanStop();
        }
        if (mounted) {
          setState(() {
            _isChecked = value;
          });
        }
      },
    );
  }

  Future logoutBtn() {
    return showDialog(
        context: context,
        barrierDismissible: false, // 바깥 영역 터치시 닫을지 여부
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('로그아웃'),
            content: SingleChildScrollView(
              child: ListBody(
                children: const <Widget>[
                  Text('로그인 페이지로 이동하시겠습니까?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('ok'),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const Login()));
                },
              ),
              TextButton(
                child: const Text('cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  /* UI */
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future(() => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Page'),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              onPressed: () {
                logoutBtn();
              },
              icon: const Icon(
                Icons.logout_rounded,
              ),
            ),
          ],
        ),
        body: Column(
          /* 장치 리스트 출력 */
          children: [
            bluetoothSwitch(),
            Expanded(
              child: ListView.separated(
                itemCount: scanResultList.length,
                itemBuilder: (context, index) {
                  return listItem(scanResultList[index]);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider();
                },
              ),
            ),
            Container(
                //child: _isLoading ? const Loader() : Container(),
                padding: const EdgeInsets.all(10.0),
                color: check ? Colors.blue : Colors.red,
                child: Text(viewTxt)),
          ],
        ),
        /* 장치 검색 or 검색 중지  */
        // floatingActionButton: FloatingActionButton(
        //   onPressed: scan,
        //   // 스캔 중이라면 stop 아이콘을, 정지상태라면 search 아이콘으로 표시
        //   child: Icon(_isScanning ? Icons.stop : Icons.search),
        // ),
      ),
    );
  }
}
