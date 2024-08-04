import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_messenger/manager/userManager.dart';

class RouteAdapter extends NavigatorObserver {
  final WidgetRef ref;

  RouteAdapter(this.ref);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _onRouteChanged(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _onRouteChanged(previousRoute);
  }

  void _onRouteChanged(Route? route) async {
    if (route != null && route.settings.name != chat() ) {
      await ref.read(userManager.notifier).unselectRoom();
    }

  }

  static String auth() { return "/"; }

  static String chats() { return "/chats"; }

  static String chat() { return "/chat"; }

  static String profile() { return "/profile"; }

}