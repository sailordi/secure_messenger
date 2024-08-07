import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../manager/userManager.dart';
import '../models/roomData.dart';
import 'buttonWidget.dart';
import 'imageWidget.dart';

class RoomsWidget extends ConsumerStatefulWidget {
  final Future<void> Function(int,BuildContext)? chat;

  const RoomsWidget({super.key, this.chat});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RoomsWidgetState();

}

class _RoomsWidgetState extends ConsumerState<RoomsWidget> {

  @override
  Widget build(BuildContext context) {
    var roomsM = ref.watch(roomsManager);

    return ListView.builder(
        shrinkWrap: true,
        itemCount: roomsM.length,
        itemBuilder: (context,index) {
          return Column(
            children: [
              _RoomsDataWidget(
                roomsData: roomsM[index],
                chatRoom: () async { await widget.chat!(index,context); }
              ),
              (roomsM.length-1 == index) ? const SizedBox() :
              const SizedBox(height: 20,)
            ],
          );
        }
    );
  }

}

class _RoomsDataWidget extends StatelessWidget {
  final RoomData roomsData;
  final void Function()? chatRoom;

  const _RoomsDataWidget({super.key,required this.roomsData,this.chatRoom});

  @override
  Widget build(BuildContext context) {
    var user = roomsData.otherUser!;


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
                ImageWidget(url: user.profilePicUrl, height: 50),
                const SizedBox(width: 5,),
                ButtonWidget(
                  width: 300,
                  height: 67,
                  text: "Send invite",
                  fontSize: 15,
                  tap: chatRoom,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  textColor: Theme.of(context).colorScheme.primary,
                )
              ],),
            const SizedBox(height: 5,),
            Text("Name: ${user.userName}"),
            Text("Email: ${user.email}"),
            const SizedBox(height: 5,),
            Text("Chat type: ${RoomData.typeToString(roomsData.type)}")
          ],
        )
    );

  }

}