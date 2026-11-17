class UserModel {
  final int? id;
  final String username;
  final String password;

  UserModel({
    this.id,
    required this.username,
    required this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password': password,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}
