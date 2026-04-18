class LoginProfile {
  final int? id;
  final String profileName;
  final String host;
  final int port;
  final String username;
  final String password;

  LoginProfile({
    this.id,
    required this.profileName,
    required this.host,
    this.port = 8728,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileName': profileName,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory LoginProfile.fromMap(Map<String, dynamic> map) {
    return LoginProfile(
      id: map['id'],
      profileName: map['profileName'],
      host: map['host'],
      port: map['port'],
      username: map['username'],
      password: map['password'],
    );
  }

  LoginProfile copyWith({
    int? id,
    String? profileName,
    String? host,
    int? port,
    String? username,
    String? password,
  }) {
    return LoginProfile(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}
