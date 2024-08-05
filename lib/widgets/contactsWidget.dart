import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../manager/userManager.dart';
import '../models/userData.dart';
import 'buttonWidget.dart';
import 'imageWidget.dart';

class ContactsWidgetPortfolio extends ConsumerStatefulWidget {
  final Future<void> Function(int,BuildContext)? remove;

  const ContactsWidgetPortfolio({super.key, this.remove});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContactsWidgetPortfolioState();

}

class ContactsWidgetRooms extends ConsumerStatefulWidget {
  final Future<void> Function(int,BuildContext)? secureRoom;
  final Future<void> Function(int,BuildContext)? normalRoom;

  const ContactsWidgetRooms({super.key, this.secureRoom,this.normalRoom});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContactsWidgetRoomsState();

}

class _ContactsWidgetPortfolioState extends ConsumerState<ContactsWidgetPortfolio> {

  @override
  Widget build(BuildContext context) {
    final contactsM = ref.watch(contactsManager);

    return ListView.builder(
        shrinkWrap: true,
        itemCount: contactsM.length,
        itemBuilder: (context,index) {
          return Column(
            children: [
              _ContactWidgetProfile(
                  user: contactsM[index],
                  remove: () async { await widget.remove!(index,context); }
              ),
              (contactsM.length-1 == index) ? const SizedBox() :
              const SizedBox(height: 20,)
            ],
          );
        }
    );
  }

}

class _ContactsWidgetRoomsState extends ConsumerState<ContactsWidgetRooms> {

  @override
  Widget build(BuildContext context) {
    final contactsM = ref.watch(contactsManager);

    return ListView.builder(
        shrinkWrap: true,
        itemCount: contactsM.length,
        itemBuilder: (context,index) {
          return Column(
            children: [
              _ContactWidgetRooms(
                  user: contactsM[index],
                  secureRoom: () async { await widget.secureRoom!(index,context); },
                  normalRoom: () async { await widget.normalRoom!(index,context); },
              ),
              (contactsM.length-1 == index) ? const SizedBox() :
              const SizedBox(height: 20,)
            ],
          );
        }
    );
  }

}

class _ContactWidgetProfile extends StatelessWidget {
  final UserData user;
  final void Function()? remove;

  const _ContactWidgetProfile({super.key,required this.user,this.remove});

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
            const SizedBox(height: 20),
            ButtonWidget(
              width: MediaQuery.of(context).size.width-70,
              height: 74.0,
              text: "Remove",
              tap: remove,
              color: Theme.of(context).colorScheme.inversePrimary,
              textColor: Theme.of(context).colorScheme.primary,
            ),
          ],
        )
    );


  }

}

class _ContactWidgetRooms extends StatelessWidget {
  final UserData user;
  final void Function()? secureRoom,normalRoom;

  const _ContactWidgetRooms({super.key,required this.user,this.secureRoom,this.normalRoom});

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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 10,),
                IconButton(
                  icon: const Icon(Icons.mail_lock),
                  onPressed: secureRoom,
                  tooltip: "Create secure chat",
                ),
                const SizedBox(width: 10,),
                IconButton(
                  icon: const Icon(Icons.mail),
                  onPressed: secureRoom,
                  tooltip: "Create chat",
                ),
                const SizedBox(width: 10,),
              ],
            )
          ],
        )
    );


  }

}
