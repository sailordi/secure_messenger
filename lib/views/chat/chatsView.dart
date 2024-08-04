import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_messenger/widgets/roomsWidget.dart';

import '../../adapters/routeAdapter.dart';
import '../../manager/userManager.dart';
import '../../widgets/drawerWidget.dart';

class ChatsView extends ConsumerStatefulWidget {
  const ChatsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatsViewState();
}

class _ChatsViewState extends ConsumerState<ChatsView> with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }
  
  Future<void> chat(int index,BuildContext context) async {
    await ref.read(userManager.notifier).selectRoom(index);
    if(context.mounted) {
      Navigator.pushNamed(context,RouteAdapter.chat() );
    }

  } 

  @override
  Widget build(BuildContext context) {
    var roomsM = ref.watch(roomsManager);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Secure-messenger: chats"),
        ),
        drawer: const DrawerWidget(),
        body: ListView.builder(
            shrinkWrap: true,
            itemCount: roomsM.length,
            itemBuilder: (context,index) {
              return Column(
                children: [
                  RoomsWidget(roomsData: roomsM[index],chatRoom: () async { await chat(index,context); },),
                  (roomsM.length-1 == index) ? const SizedBox() :
                  const SizedBox(height: 20,)
                ],
              );
            }
        ),
    );
  }

}