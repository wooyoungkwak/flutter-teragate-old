class keyinfo  {
  final int commute_key;

  keyinfo (this.commute_key);

  keyinfo.fromJson(Map<String, dynamic> json)
      : commute_key = json['commute_key']
        ;
  Map<String, dynamic> toJson() => {
        'commute_key': commute_key,
      };
}
