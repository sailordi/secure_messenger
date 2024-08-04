
typedef Users = List<UserData>;

class UserData {
  final String id;
  final String userName;
  final String email;
  final String profilePicUrl;

  const UserData({required this.id,required this.userName,required this.email,required this.profilePicUrl});

  UserData.empty() : id = "",userName = "",email="",profilePicUrl = "";

  UserData.fresh({required this.id,required this.userName,required this.email,required this.profilePicUrl});

  UserData copyWith({String? id,String? userName,String? email,String? profilePicUrl,String? aboutMe}) {
    return UserData(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );

  }

  UserData.fromDb(Map<String,dynamic> data) : id=data['id'],
        userName = data['userName'],
        email = data['email'],
        profilePicUrl = data['profilePicUrl'];

  Map<String,dynamic> toDb() {
    return {
      'id':id,
      'userName':userName,
      'email':email,
      'profilePicUrl':profilePicUrl
    };

  }

}