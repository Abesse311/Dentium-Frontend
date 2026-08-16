import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/controllers/connectivity_controller.dart';
import 'package:flutter_application_1/main.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentalClinicApp());
    expect(find.byType(DentalClinicApp), findsOneWidget);

    if (Get.isRegistered<ConnectivityController>()) {
      Get.find<ConnectivityController>().onClose();
      Get.delete<ConnectivityController>(force: true);
    }
    await tester.pump(const Duration(milliseconds: 100));
  });
}
