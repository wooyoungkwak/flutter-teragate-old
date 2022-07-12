import 'package:http/http.dart' as http;

// device IP 확인
class IpInfoApi {
  static Future<String?> getIPAddress() async {
    try {
      final url = Uri.parse('https://api.ipify.org');
      final response = await http.get(url);
      print("####################response");
      print(response.body);
      return response.body;
    } catch (e) {
      return null;
    }
  }
}
