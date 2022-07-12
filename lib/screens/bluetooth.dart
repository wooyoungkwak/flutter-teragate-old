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

  late BluetoothDevice bluetoothDevice;

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

  /* 연결 시작 */
  Future<bool> connect(device) async {
    bluetoothDevice = device;
    Future<bool>? returnValue;
    if (mounted) {
      setState(() {
        /* 상태 표시를 Connecting으로 변경 */
        stateText = '연결중';
      });
    }

    progressDialog.style(message: stateText);
    progressDialog.show();

    /* 
      타임아웃을 10초(10000ms)로 설정 및 autoconnect 해제
      참고로 autoconnect가 true되어있으면 연결이 지연되는 경우가 있음.
     */
    await bluetoothDevice
        .connect(autoConnect: false)
        .timeout(const Duration(milliseconds: 10000), onTimeout: () {
      //타임아웃 발생
      //returnValue를 false로 설정
      returnValue = Future.value(false);
      showSnackBar(context, 'timeout failed');
      //연결 상태 disconnected로 변경
      setState(() {
        var state = setBleConnectionState(BluetoothDeviceState.disconnected);
        deviceState = BluetoothDeviceState.disconnected;
      });
    }).then((data) {
      if (returnValue == null) {
        //returnValue가 null이면 timeout이 발생한 것이 아니므로 연결 성공
        debugPrint('연결 완료');
        returnValue = Future.value(true);
        setState(() {
          //연결 상태 disconnected로 변경
          var state = setBleConnectionState(BluetoothDeviceState.connected);
          deviceState = BluetoothDeviceState.connected;

          print(deviceState);
        });
      }
    });
    showEndProgress(deviceState);
    return returnValue ?? Future.value(false);
  }

  /* 연결 해제 */
  void disconnect(device) {
    bluetoothDevice = device;
    try {
      setState(() {
        stateText = '연결해제중';
        progressDialog.style(message: stateText);
        progressDialog.show();
      });
      deviceState = BluetoothDeviceState.disconnecting;
      bluetoothDevice.disconnect();
      showEndProgress(deviceState);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void showEndProgress(event) async {
    deviceState = event;
    var state = setBleConnectionState(event);
    progressDialog.update(message: state[0]);
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
              timeout: const Duration(seconds: 30))
          .timeout(const Duration(seconds: 30), onTimeout: () async {
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
        //results.clear();
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
    await Future.delayed(const Duration(seconds: 10), () async {
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
  Widget deviceMacAddress(ScanResult scanResult) {
    return Text(scanResult.device.id.id);
  }

  /* 장치의 명 위젯  */
  Widget deviceName(ScanResult scanResult) {
    String name = '';

    if (scanResult.device.name.isNotEmpty) {
      // device.name에 값이 있다면
      name = scanResult.device.name;
    } else if (scanResult.advertisementData.localName.isNotEmpty) {
      // advertisementData.localName에 값이 있다면
      name = scanResult.advertisementData.localName;
    } else {
      // 둘다 없다면 이름 알 수 없음...
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE 아이콘 위젯 */
  Widget leading(ScanResult scanResult) {
    return const CircleAvatar(
      child: Icon(
        Icons.bluetooth_connected,
        color: Colors.white,
      ),
      backgroundColor: Colors.cyan,
    );
  }

  /* 장치 아이템을 탭 했을때 호출 되는 함수 */
  void onTap(ScanResult scanResult) async {
    flutterBlue.stopScan();
    // 단순히 이름만 출력
    debugPrint(scanResult.device.name);
    print(deviceState);
    progressDialog = ProgressDialog(context,
        type: ProgressDialogType.normal, isDismissible: true, showLogs: true);
    if (deviceState == BluetoothDeviceState.connected) {
      /* 연결된 상태라면 연결 해제 */
      disconnect(scanResult.device);
    } else if (deviceState == BluetoothDeviceState.disconnected) {
      /* 연결 해재된 상태라면 연결 */
      connect(scanResult.device);
    } else {}
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => Device(device: r.device)),
    // );
    //await r.device.connect();
  }

  /* 장치 아이템 위젯 */
  Widget listItem(ScanResult scanResult) {
    var state = setBleConnectionState(deviceState);
    stateText = state[0];
    stateConnect = state[1];
    IconData icon = Icons.bluetooth_disabled;
    if (stateConnect) {
      icon = Icons.bluetooth_connected;
    } else {
      icon = Icons.bluetooth_disabled;
    }
    return ListTile(
      onTap: () => onTap(scanResult),
      leading: leading(scanResult),
      title: deviceName(scanResult),
      subtitle: deviceMacAddress(scanResult),
      trailing: Icon(icon),
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
