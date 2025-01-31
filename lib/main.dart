import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

import 'adapters/routeAdapter.dart';
import 'views/auth/authView.dart';
import 'views/chat/chatView.dart';
import 'views/chat/chatsView.dart';
import 'views/profile/profileView.dart';
import 'helper/myTheme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context,WidgetRef ref) {
    return ProviderScope(
        child: MaterialApp(
          title: 'Secure-messenger',
          theme: MyTheme.lightMode(),
          darkTheme: MyTheme.darkMode(),
          navigatorObservers: [RouteAdapter(ref)],
          initialRoute: "/",
          routes: {
            RouteAdapter.auth(): (context) => const AuthView(),
            RouteAdapter.chats(): (context) => const ChatsView(),
            RouteAdapter.chat(): (context) => const ChatView(),
            RouteAdapter.profile(): (context) => const ProfileView(),
          },
          debugShowCheckedModeBanner: false,
        )
    );
  }

}