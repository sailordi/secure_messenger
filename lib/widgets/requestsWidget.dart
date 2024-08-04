import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../manager/userManager.dart';
import '../models/userData.dart';
import 'buttonWidget.dart';
import 'imageWidget.dart';

class SentRequestsWidget extends ConsumerStatefulWidget {
  const SentRequestsWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SentRequestsWidgetState();

}

class ReceivedRequestsWidget extends ConsumerStatefulWidget {
  final Future<void> Function(int,BuildContext)? accept;
  final Future<void> Function(int,BuildContext)? decline;

  const ReceivedRequestsWidget({super.key,required this.accept,required this.decline});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ReceivedRequestsWidgetState();

}

class _SentRequestsWidgetState extends ConsumerState<SentRequestsWidget> {
  @override
  Widget build(BuildContext context) {
    final sentReqM = ref.watch(sentReqManager);

    return ListView.builder(
        shrinkWrap: true,
        itemCount: sentReqM.length,
        itemBuilder: (context,index) {
          return Column(
            children: [
              _RequestWidget(
                  received: false,
                  user: sentReqM[index].receiver!,
                  accept: null,
                  decline: null
              ),
              (sentReqM.length-1 == index) ? const SizedBox() :
              const SizedBox(height: 20,)
            ],
          );
        }
    );
  }

}

class _ReceivedRequestsWidgetState extends ConsumerState<ReceivedRequestsWidget> {
  @override
  Widget build(BuildContext context) {
    final receivedReqM = ref.watch(receivedReqManager);

    return ListView.builder(
        shrinkWrap: true,
        itemCount: receivedReqM.length,
        itemBuilder: (context,index) {
          return Column(
            children: [
              _RequestWidget(
                  received: false,
                  user: receivedReqM[index].receiver!,
                  accept: () async { await widget.accept!(index,context); },
                  decline: () async { await widget.decline!(index,context); }
              ),
              (receivedReqM.length-1 == index) ? const SizedBox() :
              const SizedBox(height: 20,)
            ],
          );
        }
    );
  }

}

class _RequestWidget extends StatelessWidget {
  final UserData user;
  final bool received;
  final void Function()? accept;
  final void Function()? decline;

  const _RequestWidget({super.key,required this.user,required this.received,this.accept,this.decline});

  dynamic buttons(BuildContext context) {
    if(!received) {
      return const SizedBox();
    }
    var width = MediaQuery.of(context).size.width-70;
    var height = 74.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 10,),
        ButtonWidget(
          width: width/2,
          height: height,
          text: "Accept",
          tap: accept,
          color: Theme.of(context).colorScheme.inversePrimary,
          textColor: Theme.of(context).colorScheme.primary,

        ),
        const SizedBox(width: 5,),
        ButtonWidget(
          width: width/2,
          height: height,
          text: "Decline",
          tap: decline,
          color: Theme.of(context).colorScheme.inversePrimary,
          textColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10,),
      ],
    );
  }

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageWidget(url: user.profilePicUrl, height: 50),
            const SizedBox(height: 5,),
            Text("Name: ${user.userName}",
              style: const TextStyle(
                  fontSize: 18
              ),
            ),
            const SizedBox(width: 5,),
            Text("Email: ${user.email}",
              style: const TextStyle(
                  fontSize: 18
              ),
            ),
            (!received) ? const SizedBox() : const SizedBox(height: 20),
            buttons(context),
          ],
        )
    );

  }

}
