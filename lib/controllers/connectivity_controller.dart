import 'dart:async';
import 'package:get/get.dart';
import '../core/api/api_client.dart';

class ConnectivityController extends GetxController {
  static ConnectivityController get to => Get.find();

  final RxBool isConnected = false.obs;
  final RxBool isChecking = false.obs;
  final RxString lastError = ''.obs;
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    checkConnection();
    // Periodically poll health every 15 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      checkConnection();
    });
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    super.onClose();
  }

  Future<void> checkConnection() async {
    if (isChecking.value) return;
    isChecking.value = true;
    try {
      final healthy = await ApiClient.instance.checkConnection();
      isConnected.value = healthy;
      if (!healthy) {
        lastError.value = 'Serveur local non détecté sur 127.0.0.1:8000';
      } else {
        lastError.value = '';
      }
    } catch (e) {
      isConnected.value = false;
      lastError.value = e.toString();
    } finally {
      isChecking.value = false;
    }
  }
}
