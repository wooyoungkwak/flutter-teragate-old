// ignore: camel_case_types
class attenduser {
  int user_id;
  String kr_name;

  attenduser(this.user_id,this.kr_name);

  attenduser.fromJson(Map<String, dynamic> json) : 
  user_id = json['user_id'],
  kr_name = json['kr_name']
  ;
  Map<String, dynamic> toJson() => {
        'user_id': user_id,
        'kr_name': kr_name,
      };
}
