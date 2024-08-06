import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tab_container/tab_container.dart';

import '../../adapters/routeAdapter.dart';
import '../../helper/helper.dart';
import '../../manager/userManager.dart';
import '../../models/myError.dart';
import '../../models/roomData.dart';
import '../../widgets/drawerWidget.dart';
import '../../widgets/contactsWidget.dart';
import '../../widgets/roomsWidget.dart';

class ChatsView extends ConsumerStatefulWidget {
  const ChatsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatsViewState();
}

class _ChatsViewState extends ConsumerState<ChatsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _chat(int index,BuildContext context) async {
    await ref.read(userManager.notifier).selectRoom(index);
    if(context.mounted) {
      Navigator.pushNamed(context,RouteAdapter.chat() );
    }

  }

  Future<void> _createSecureChat(int index,BuildContext context) async {
    try {
      await ref.read(userManager.notifier).createRoom(index,RoomType.secure);
    }on MyError catch(e) {
      if(context.mounted) {
        Helper.messageToUser(e.text, context);
      }
      return;
    }

    if(context.mounted) {
      Navigator.pushNamed(context,RouteAdapter.chat() );
    }

  }

  Future<void> _createChat(int index,BuildContext context) async {
    try {
      await ref.read(userManager.notifier).createRoom(index,RoomType.normal);
    }on MyError catch(e) {
      if(context.mounted) {
        Helper.messageToUser(e.text, context);
      }
      return;
    }

    if(context.mounted) {
      Navigator.pushNamed(context,RouteAdapter.chat() );
    }

  }

  dynamic _contactsList() {
    return Column(
      children: [
        Flexible(
          child: ContactsWidgetRooms(normalRoom: _createChat,secureRoom:_createSecureChat),
        )
      ],
    );

  }

  dynamic _chatList() {
    return Column(
      children: [
        Flexible(
          child: RoomsWidget(chat: _chat),
        )
      ],
    );
  }

  dynamic _tabContainer(BuildContext context) {
    const heightRem = 350;

    return TabContainer(
      controller: _tabController,
      tabEdge: TabEdge.top,
      tabsStart: 0.1,
      tabsEnd: 0.9,
      tabMaxLength: 120,
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
      ],
      tabs: const [
        Text('Contacts'),
        Text('Chats'),
      ],
      children: [
        SizedBox(
            height: MediaQuery.of(context).size.height-heightRem,
            child: _contactsList()
        ),
        SizedBox(
            height: MediaQuery.of(context).size.height-heightRem,
            child: _chatList()
        ),
      ],
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Secure-messenger: chats"),
        ),
        drawer: const DrawerWidget(),
        body:Column(
          children: [
            const SizedBox(height: 5,),
            _tabContainer(context)
          ],
        )
    );
  }

}