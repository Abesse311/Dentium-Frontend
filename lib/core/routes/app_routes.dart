import 'package:get/get.dart';
import '../../screens/shell_screen.dart';

class AppRoutes {
  static const String shell = '/';
  static const String dashboard = '/dashboard';
  static const String patients = '/patients';
  static const String appointments = '/appointments';
  static const String treatments = '/treatments';
  static const String invoices = '/invoices';
  static const String settings = '/settings';

  static final List<GetPage> pages = [
    GetPage(
      name: shell,
      page: () => const ShellScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
