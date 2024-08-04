import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../manager/userManager.dart';
import '../models/userData.dart';
import 'buttonWidget.dart';
import 'imageWidget.dart';

class ContactsWidget extends ConsumerStatefulWidget {
  final Future<void> Function(int,BuildContext)? remove;

  const ContactsWidget({super.key, this.remove});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ContactsWidgetState();

}

class _ContactsWidgetState extends ConsumerState<ContactsWidget> {

  @override
  Widget build(BuildContext context) {
    final contactsM = ref.watch(contactsManager);

    return ListView.builder(
        shrinkWrap: true,
        itemCount: contactsM.length,
        itemBuilder: (context,index) {
          return Column(
            children: [
              _ContactWidget(
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


class _ContactWidget extends StatelessWidget {
  final UserData user;
  final void Function()? remove;

  const _ContactWidget({super.key,required this.user,this.remove});

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
            const SizedBox(height: 20),
          ],
        )
    );


  }

}
