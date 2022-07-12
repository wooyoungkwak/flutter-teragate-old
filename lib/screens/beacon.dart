import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:beacons_plugin/beacons_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:tera_gate_app/models/attendinfo.dart';
import 'package:tera_gate_app/models/beaconModel.dart';
import 'package:tera_gate_app/models/keyModel.dart';
import 'package:tera_gate_app/service/ip_info_api.dart';
import 'package:tera_gate_app/service/leaveService.dart';

import '../env.dart';
import '../service/attendService.dart';
import '../utils/permission.dart';
import 'login.dart';
import 'webview2.dart';

//현재시간
import 'package:date_format/date_format.dart';
import 'package:timer_builder/timer_builder.dart';

class Beacon extends StatefulWidget {
  const Beacon({Key? key}) : super(key: key);

  @override
  _BeaconState createState() => _BeaconState();
}

class _BeaconState extends State<Beacon> with WidgetsBindingObserver {
  String formattedDate = "";
  DateTime now = DateTime.now();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  String _tag = "Beacons Plugin";
  String _beaconResult = 'Not Scanned Yet.';
  int _nrMessagesReceived = 0;
  var isRunning = false;
  List<String> _results = [];
  bool _isInForeground = true;
  String? deviceip = "00";
  String? userId = "1";
  String? name = "test";
  var flutterSecureStorage = new FlutterSecureStorage();
  String? data1 = "test1";
  String? data2 = "test2";

  late DateTime alert;

  final ScrollController _scrollController = ScrollController();

  final StreamController<String> beaconEventsController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    init();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    alert = DateTime.now().add(Duration(seconds: 10));

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: null);
  }

  Future init() async {
    //사용하는 기기의 IP 가져오기
    final ipAddress = await IpInfoApi.getIPAddress();

    if (!mounted) return;

    deviceip = ipAddress;
    print(deviceip);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    beaconEventsController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      //Prominent disclosure
      await BeaconsPlugin.setDisclosureDialogMessage(
          title: "Background Locations",
          message:
              "[This app] collects location data to enable [feature], [feature], & [feature] even when the app is closed or not in use");

      //Only in case, you want the dialog to be shown again. By Default, dialog will never be shown if permissions are granted.
      //await BeaconsPlugin.clearDisclosureDialogShowFlag(false);
    }

    if (Platform.isAndroid) {
      BeaconsPlugin.channel.setMethodCallHandler((call) async {
        print("Method: ${call.method}");
        if (call.method == 'scannerReady') {
          _showNotification("Beacons monitoring started..");
          await BeaconsPlugin.startMonitoring();
          setState(() {
            isRunning = true;
          });
        } else if (call.method == 'isPermissionDialogShown') {
          _showNotification(
              "Prominent disclosure message is shown to the user!");
        }
      });
    } else if (Platform.isIOS) {
      _showNotification("Beacons monitoring started..");
      await BeaconsPlugin.startMonitoring();
      setState(() {
        isRunning = true;
      });
    }

    BeaconsPlugin.listenToBeacons(beaconEventsController);

    /* BeaconsPlugin.addRegion("myBeacon", "01022022-f88f-0000-00ae-9605fd9bb620");
    BeaconsPlugin.addRegion("iBeacon", "12345678-1234-5678-8f0c-720eaf059935");
 */

    await BeaconsPlugin.addRegion(
        "Teraenergy", "12345678-1234-5678-8f0c-720eaf059935");

    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=beac,i:4-19,i:20-21,i:22-23,p:24-24,d:25-25");
    BeaconsPlugin.addBeaconLayoutForAndroid(
        "m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24");

    BeaconsPlugin.setForegroundScanPeriodForAndroid(
        foregroundScanPeriod: 2200, foregroundBetweenScanPeriod: 10);

    BeaconsPlugin.setBackgroundScanPeriodForAndroid(
        backgroundScanPeriod: 2200, backgroundBetweenScanPeriod: 10);

    beaconEventsController.stream.listen(
        (data) async {
          if (data.isNotEmpty && isRunning) {
            if (_nrMessagesReceived <= 2) {
              setState(() {
                _beaconResult = data;
                _results.add("출근 처리 중입니다");
                _nrMessagesReceived++;
              });

              if (!_isInForeground) {
                _showNotification("Beacons DataReceived: " + data);
              }

              print("Beacons DataReceived: " + data);
            }
            if (_nrMessagesReceived == 2) {
              BeaconsPlugin.stopMonitoring(); //모니터링 종료
              setState(() {
                //스캔 종료
                isRunning = !isRunning;
              });

              Map<String, dynamic> userMap = jsonDecode(data);
              print(userMap);
              var iBeacon = User.fromJson(userMap);
              print('안녕하세요, ${iBeacon.name} 회사!');
              print('${iBeacon.minor} 오늘의 인증 key 입니다(비콘)');

              String becon_key = '${iBeacon.minor}'; // 비콘의 key 값
              bool key_succes = false; // key 일치여부 확인

              //DB에서 key 가져오기
/*               var url = Uri.parse("${Env.URL_PREFIX}/keyCheck");
              var response = await http.get(url);
              var result = utf8.decode(response.bodyBytes);
              Map<String, dynamic> keyMap = jsonDecode(result);
              var cheak_key = keyinfo.fromJson(keyMap);
              print('DB key :' + '${cheak_key.commute_key}');
              String db_key = '${cheak_key.commute_key}'; 임시제거 */

              String db_key = '50000'; //임시로 고정

              userId = await flutterSecureStorage.read(key: 'user_id');
              name = await flutterSecureStorage.read(key: 'kr_name');
              data1 = await flutterSecureStorage.read(key: 'LOGIN_ID');
              data2 = await flutterSecureStorage.read(key: 'LOGIN_PW');

              if (becon_key == db_key) {
                key_succes = true;
              } else {
                key_succes = false;
              }

              if (key_succes) {
                attendoverlapCheck(userId);
                //DB:출근 기록 확인

                if (true) {
                  //출근
                  print("#############출근진입############");
                  attend(userId, deviceip).then((data) {
                    //출근에 대한 정보 db저장
                    debugPrint(data);
                    FlutterDialog("출근하셨습니다 ${name}님!"); //다이얼로그창
                    setState(() {
                      _results.add("msg: ${name}님 출근");
                    });
                  });
                }
/*                      else {
                      print(data.success);
                      FlutterDialog(" ${name}님 이미 출근하셨습니다."); //다이얼로그창
                      setState(() {
                        _results.add("msg: ${name}님 이미 출근 하셨습니다");
                      });
                    } */

              } else {
                FlutterDialog("Key값이 다릅니다. 재시도 해주세요!"); //다이얼로그창
              }
              _nrMessagesReceived = 0;
              key_succes = false;
            }
          }
        },
        onDone: () {},
        onError: (error) {
          print("Error: $error");
        });

    //Send 'true' to run in background
    await BeaconsPlugin.runInBackground(true);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TERA GATE 출퇴근'),
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
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TimerBuilder.periodic(
                const Duration(seconds: 1),
                builder: (context) {
                  return Text(
                    formatDate(DateTime.now(), [hh, ':', nn, ':', ss, ' ', am]),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w200,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (isRunning) {
                      await BeaconsPlugin.stopMonitoring(); //비콘 스캔 시작
                    } else {
                      initPlatformState();
                      await BeaconsPlugin.startMonitoring(); //비콘 스캔 종료
                    }
                    setState(() {
                      isRunning = !isRunning;
                    });
                  },
                  child: Text(isRunning ? '출근 처리중' : '출 근',
                      style: TextStyle(fontSize: 20)),
                ),
              ),
              Visibility(
                visible: _results.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      leave_user();
                    },
                    child: Text("퇴 근", style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => webview2(data1!, data2!)));
                  },
                  child: Text('웹 뷰 ', style: TextStyle(fontSize: 20)),
                ),
              ),
              SizedBox(
                height: 20.0,
              ),
              Expanded(child: _buildResultsList())
            ],
          ),
        ),
      ),
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

  //퇴근 기능
  void leave_user() {
    leave(userId, deviceip).then((data) {
      if (data.success) {
        print("#############퇴근진입############");
        FlutterDialog("퇴근하셨습니다 ${name}님!"); //다이얼로그창
      } else {
        FlutterDialog("퇴근처리가 안됩니다"); //다이얼로그창
      }
      setState(() {
        _results.add("msg: ${name}님 퇴근");
      });
    });
  }

  void _showNotification(String subtitle) {
    var rng = new Random();
    Future.delayed(Duration(seconds: 5)).then((result) async {
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'your channel id', 'your channel name',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker');
      var iOSPlatformChannelSpecifics = IOSNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          rng.nextInt(100000), _tag, subtitle, platformChannelSpecifics,
          payload: 'item x');
    });
  }

  void FlutterDialog(String text) {
    showDialog(
        context: context,
        //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            //Dialog Main Title
            title: Column(
              children: <Widget>[
                const Text("Dialog Title"),
              ],
            ),
            //
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                ),
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                child: const Text("확인"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  Widget _buildResultsList() {
    return Scrollbar(
      isAlwaysShown: true,
      controller: _scrollController,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ScrollPhysics(),
        controller: _scrollController,
        itemCount: _results.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Colors.black,
        ),
        itemBuilder: (context, index) {
          formattedDate = DateFormat('yyyy-MM-dd – kk:mm:ss').format(now);
          final item = ListTile(
              title: Text(
                "시 간: $formattedDate\n${_results[index]}",
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      fontSize: 14,
                      color: const Color(0xFF1A1B26),
                      fontWeight: FontWeight.normal,
                    ),
              ),
              onTap: () {});
          return item;
        },
      ),
    );
  }
}
