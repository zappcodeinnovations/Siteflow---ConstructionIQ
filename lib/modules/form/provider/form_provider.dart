import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/form_controller.dart';
import '../model/form_model.dart';

class SubmitFormParams {
  final String formId;
  final String? projectId;
  final String? jobId;
  final Map<String, String>? fields;

  SubmitFormParams({
    required this.formId,
    this.projectId,
    this.jobId,
    this.fields,
  });
}

/// ✅ CONTROLLER PROVIDER
final formsControllerProvider = Provider<FormsController>((ref) {
  return FormsController();
});

/// ✅ GET FORMS LIST (AUTO CACHE + REFRESH)
final formsListProvider = FutureProvider.autoDispose<List<FormItem>>((
  ref,
) async {
  final controller = ref.read(formsControllerProvider);

  /// 🔥 Keeps data alive for some time (optional but useful)
  ref.keepAlive();

  return controller.fetchForms();
});

/// ✅ SUBMIT FORM (ACTION PROVIDER 🔥)
final submitFormProvider = FutureProvider.family<bool, SubmitFormParams>((
  ref,
  params,
) async {
  final controller = ref.read(formsControllerProvider);

  final result = await controller.submitForm(
    formId: params.formId,
    projectId: params.projectId,
    jobId: params.jobId,
    fields: params.fields,
  );

  /// 🔥 Refresh forms after submit (optional)
  ref.invalidate(formsListProvider);

  return result;
});
