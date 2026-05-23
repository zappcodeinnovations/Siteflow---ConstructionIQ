import '../model/form_status_kpi_model.dart';

class FormStatusKpiState {
  final bool isLoading;
  final String? error;
  final FormStatusKpiModel? data;

  const FormStatusKpiState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  FormStatusKpiState copyWith({
    bool? isLoading,
    String? error,
    FormStatusKpiModel? data,
  }) {
    return FormStatusKpiState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}