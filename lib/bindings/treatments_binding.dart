import 'package:get/get.dart';
import '../controllers/treatments_controller.dart';

class TreatmentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TreatmentsController>(() => TreatmentsController());
  }
}
