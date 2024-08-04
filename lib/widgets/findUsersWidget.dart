import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../manager/userManager.dart';
import '../models/userData.dart';
import 'buttonWidget.dart';
import 'expandedButtonWidget.dart';
import 'imageWidget.dart';
import 'package:secure_messenger/widgets/textFieldWidget.dart';

class FindUsersWidget extends ConsumerStatefulWidget {
  final Future<void> Function(int,BuildContext)? sendInvite;

  const FindUsersWidget({super.key,this.sendInvite});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FindUsersWidgetState();

}

class _FindUsersWidgetState extends ConsumerState<FindUsersWidget> {
  final TextEditingController _findUserC = TextEditingController();

  dynamic _findUserList(Users users) {
    if(users.isEmpty && _findUserC.text.isEmpty) {
      return const SizedBox();
    }
    if(users.isEmpty && _findUserC.text.isNotEmpty) {
      return Text("User with username/email ${_findUserC.text} could be found");
    }

    return Flexible(
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: users.length,
          itemBuilder: (context,index) {
            return Column(
              children: [
                _FoundUserWidget(
                  user: users[index],
                  sendInvite: () async { await widget.sendInvite!(index,context); },
                ),
                (index != users.length-1) ? const SizedBox(height: 20,) : const SizedBox(),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foundUsers = ref.watch(foundUsersManager);

    return Column(
      children: [
        const Text("Search for user: ",
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 5,),
        (context.mounted == false) ? const SizedBox() :
        TextFieldWidget(
          hint: "Username/email",
          controller: _findUserC,
          align: TextAlign.center,
        ),
        const SizedBox(height: 5,),
        SizedBox(
            height: 67,
            child: ExpandedButtonWidget(
              text: "Find user",
              fontSize: 15,
              tap: () async { await ref.read(userManager.notifier).findUser(_findUserC.text); },
              color: Theme.of(context).colorScheme.inversePrimary,
              textColor: Theme.of(context).colorScheme.primary,
            )
        ),
        const SizedBox(height: 50,),
        _findUserList(foundUsers),
        const SizedBox(height: 5,),
      ],
    );

  }

}

class _FoundUserWidget extends StatelessWidget {
  final UserData user;
  final void Function()? sendInvite;

  const _FoundUserWidget({super.key,required this.user,this.sendInvite});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.black,
              width: 2
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        width: MediaQuery.of(context).size.width-20,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ImageWidget(url: user.profilePicUrl, height: 70),
                const SizedBox(width: 5,),
                ButtonWidget(
                  width: 300,
                  height: 67,
                  text: "Send invite",
                  fontSize: 15,
                  tap: sendInvite,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  textColor: Theme.of(context).colorScheme.primary,
                )
              ],),
            const SizedBox(width: 5,),
            Text("Name: ${user.userName}"),
            Text("Email: ${user.email}"),
            const SizedBox(width: 10,),
          ],
        )
    );

  }

}
