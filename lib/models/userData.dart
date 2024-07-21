
typedef Users = List<UserData>;

class UserData {
  final String id;
  final String userName;
  final String email;
  final String profilePicUrl;
  final String aboutMe;

  const UserData({required this.id,required this.userName,required this.email,required this.profilePicUrl,required this.aboutMe});

  UserData.empty() : id = "",userName = "",email="",profilePicUrl = "",aboutMe = "";

  UserData copyWith({String? id,String? userName,String? email,String? profilePicUrl,String? aboutMe}) {
    return UserData(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      aboutMe: aboutMe ?? this.aboutMe,
    );

  }

}