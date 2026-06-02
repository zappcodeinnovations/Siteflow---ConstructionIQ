import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/form_controller.dart';
import '../model/form_model.dart';
import '../model/form_status_kpi_model.dart';

/// 🔥 SUBMIT PARAMS
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

/// ✅ GET FORMS LIST
final formsListProvider = FutureProvider.autoDispose<List<FormItem>>((
  ref,
) async {
  final controller = ref.read(formsControllerProvider);

  /// 🔥 Keep cache alive
  ref.keepAlive();

  return controller.fetchForms();
});

/// ✅ GET SELECTED FORMS FOR A JOB
final selectedJobFormsProvider = FutureProvider.autoDispose
    .family<List<FormItem>, int>((ref, jobId) async {
      final controller = ref.read(formsControllerProvider);

      ref.keepAlive();

      return controller.fetchSelectedJobForms(jobId);
    });

/// ✅ GET FORM STATUS KPI
final formStatusKpiProvider = FutureProvider.autoDispose<FormStatusKpiModel>((
  ref,
) async {
  final controller = ref.read(formsControllerProvider);

  ref.keepAlive();

  return controller.fetchFormStatusKpi();
});

/// ✅ SUBMIT FORM
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

  /// 🔥 Refresh forms list
  ref.invalidate(formsListProvider);

  /// 🔥 Refresh KPI data
  ref.invalidate(formStatusKpiProvider);

  return result;
});
