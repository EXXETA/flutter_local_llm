import 'package:auto_route/auto_route.dart';

import '../../features/home/view/home_screen.dart';
import '../../features/setup/view/setup_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required this.isModelInstalled});

  final bool isModelInstalled;

  @override
  List<AutoRoute> get routes => isModelInstalled
      ? [AutoRoute(page: HomeRoute.page, initial: true)]
      : [
          AutoRoute(page: SetupRoute.page, initial: true),
          AutoRoute(page: HomeRoute.page),
        ];
}
