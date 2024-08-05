import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_messenger/models/myError.dart';
import 'package:tab_container/tab_container.dart';

import '../../helper/helper.dart';
import '../../manager/userManager.dart';
import '../../models/userData.dart';
import '../../widgets/imageWidget.dart';
import '../../widgets/findUsersWidget.dart';
import '../../widgets/contactsWidget.dart';
import '../../widgets/requestsWidget.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite(int index,BuildContext context) async {
    UserData? friend;
    try {
      friend = await ref.read(userManager.notifier).sendRequest(index);
    } on MyError catch (e) {
      if(context.mounted) {
        Helper.messageToUser(e.text, context);
      }
      return;
    }

    if(context.mounted) {
      Helper.messageToUser("Sent friend request to:\n${friend.userName} (${friend.email})", context);
    }

  }

  Future<void> _acceptInvite(int index,BuildContext context) async {
    UserData? user;
    try {
      user = await ref.read(userManager.notifier).acceptRequest(index);
    } on MyError catch (e) {
      if(context.mounted) {
        Helper.messageToUser(e.text, context);
      }
      return;
    }

    if(context.mounted) {
      Helper.messageToUser("Accepted contact request from:\n${user.userName} (${user.email})", context);
    }
  }

  Future<void> _declineInvite(int index,BuildContext context) async {
    UserData? user;
    try {
      user = await ref.read(userManager.notifier).declineRequest(index);
    } on MyError catch (e) {
      if(context.mounted) {
        Helper.messageToUser(e.text, context);
      }
      return;
    }

    if(context.mounted) {
      Helper.messageToUser("Declined contact request from:\n${user.userName} (${user.email})", context);
    }

  }

  Future<void> _removeContact(int index,BuildContext context) async {
    UserData? user;
    try {
      user = await ref.read(userManager.notifier).removeContact(index);
    } on MyError catch (e) {
      if(context.mounted) {
        Helper.messageToUser(e.text, context);
      }
      return;
    }

    if(context.mounted) {
      Helper.messageToUser("Removed friend:\n${user.userName} (${user.email})", context);
    }
  }

  dynamic _contacts(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: ContactsWidgetPortfolio(remove: _removeContact)
        )
      ],
    );

  }

  dynamic _sentRequests() {
    return const Column(
      children: [
        Flexible(
          child: SentRequestsWidget(),
        )
      ],
    );

  }

  dynamic _receivedRequest()  {
    return Column(
      children: [
        Flexible(
          child: ReceivedRequestsWidget(
            accept: _acceptInvite,
            decline: _declineInvite,
          )
        ),
      ],
    );
  }

  dynamic _tabContainer(BuildContext context) {
    const heightRem = 300;

    return TabContainer(
      controller: _tabController,
      tabEdge: TabEdge.top,
      tabsStart: 0.1,
      tabsEnd: 0.9,
      tabMaxLength: 100,
      borderRadius: BorderRadius.circular(2),
      tabBorderRadius: BorderRadius.circular(2),
      childPadding: const EdgeInsets.all(10.0),
      selectedTextStyle: const TextStyle(
        color: Colors.blue,
        fontSize: 15.0,
      ),
      unselectedTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.inversePrimary,
        fontSize: 13.0,
      ),
      colors: [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.primary,
      ],
      tabs: const [
        Text('Contacts'),
        Text('Received requests'),
        Text('Sent requests'),
        Text('Find users'),
      ],
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height-heightRem,
            child: _contacts(context)
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height-heightRem,
            child: _receivedRequest()
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height-heightRem,
            child:  _sentRequests()
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height-heightRem,
            child:  FindUsersWidget(sendInvite: _sendInvite)
        ),
      ],
    );

  }

  @override
  Widget build(BuildContext context) {
    final udM = ref.watch(userDataManager);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Secure-messenger: profile"),
        ),
        body: SingleChildScrollView(
            child:  Column(
              children: [
                const SizedBox(height: 5,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 5,),
                    ImageWidget(url: udM.profilePicUrl, height: 50),
                    const SizedBox(width: 5,),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Username: ${udM.userName}"),
                        const SizedBox(width: 40,),
                        Text("Email: ${udM.email}"),
                      ],
                    ),
                    const SizedBox(width: 5,),
                  ],
                ),
                const SizedBox(height: 5,),
                _tabContainer(context)
              ],
            )
        )
    );

  }

}