import 'package:euroside/modules/form/model/form_model.dart';
import 'package:euroside/modules/form/provider/form_provider.dart';
import 'package:euroside/modules/form/view/form.dart';
import 'package:euroside/modules/job/model/job_model.dart';
import 'package:euroside/modules/job/provider/job_provider.dart';
import 'package:euroside/network/api_endpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kBlue = Color(0xFF1B5EF7);
const kBlueSoft = Color(0xFFEEF3FF);
const kBg = Color(0xFFF7F9FC);
const kTextDark = Color(0xFF0D1B2A);
const kTextMid = Color(0xFF4B5A6E);
const kTextLight = Color(0xFF9AA8BA);
const kDivider = Color(0xFFE8EDF5);
const kWhite = Color(0xFFFFFFFF);

class JobListScreen extends ConsumerStatefulWidget {
  final int projectId;

  const JobListScreen({super.key, required this.projectId});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  bool _isClockOutLoading = false;

  String _cleanErrorMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    return raw.split('|BACKEND_JSON|').first.trim();
  }

  Future<bool> _isClockedInForThisProject(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final isClockedIn = prefs.getBool("isClockedIn") ?? false;
    final clockedInProjectId = prefs.getInt("clockedInProjectId");
    return isClockedIn && clockedInProjectId == projectId;
  }

  Future<void> _openJobForm(JobModel job) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString("access_token") ?? "";

      if (accessToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again to open the form.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      var formId = job.formId;

      if (formId == 0) {
        final forms = await ref.read(formsListProvider.future);
        for (final form in forms) {
          if (form.name == job.formName) {
            formId = form.id;
            break;
          }
        }
      }

      if (formId == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form not found for ${job.formName}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserFormWebViewPage(
            title: job.formName,
            endpoint: ApiEndpoints.userFormHtml(formId),
            accessToken: accessToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanErrorMessage(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _openCreateJobSheet({bool forClockOut = false}) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CreateDayJobSheet(projectId: widget.projectId);
      },
    );

    if (!mounted) return false;

    if (created == true) {
      ref.invalidate(jobListProvider(widget.projectId));
      if (!forClockOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job added successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    }

    if (forClockOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add today\'s job before clocking out.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobListProvider(widget.projectId));

    return FutureBuilder<bool>(
      future: _isClockedInForThisProject(widget.projectId),
      builder: (context, snapshot) {
        final showClockOut = snapshot.data == true;

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kWhite,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: kDivider,
            title: const Text(
              'Jobs',
              style: TextStyle(
                color: kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            centerTitle: false,
            actions: [
              if (showClockOut)
                IconButton(
                  tooltip: 'Add Job',
                  onPressed: _isClockOutLoading
                      ? null
                      : () => _openCreateJobSheet(),
                  icon: const Icon(Icons.add_circle_outline, color: kBlue),
                ),
            ],
          ),
          body: jobAsync.when(
            data: (jobs) {
              if (jobs.isEmpty) {
                return _EmptyState(
                  canAddJob: showClockOut,
                  onAddJob: showClockOut ? _openCreateJobSheet : null,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(jobListProvider(widget.projectId));
                  await ref.read(jobListProvider(widget.projectId).future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _JobCard(
                    job: jobs[index],
                    onOpenForm: () => _openJobForm(jobs[index]),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: kBlue, strokeWidth: 2.5),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: kTextLight,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load jobs',
                      style: TextStyle(
                        color: kTextMid,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cleanErrorMessage(e),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kTextLight, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CreateDayJobSheet extends ConsumerStatefulWidget {
  final int projectId;

  const _CreateDayJobSheet({required this.projectId});

  @override
  ConsumerState<_CreateDayJobSheet> createState() => _CreateDayJobSheetState();
}

class _CreateDayJobSheetState extends ConsumerState<_CreateDayJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _siteContactController = TextEditingController();
  final _instructionsController = TextEditingController();

  String? _selectedFormName;
  int? _selectedFormId;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _referenceController.text = '';
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _siteContactController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String _cleanErrorMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    return raw.split('|BACKEND_JSON|').first.trim();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFormName == null || _selectedFormName!.isEmpty) {
      setState(() => _errorText = 'Please select a form name.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref
          .read(jobControllerProvider)
          .createJob(
            projectId: widget.projectId,
            reference: _referenceController.text.trim(),
            formName: _selectedFormName!,
            formId: _selectedFormId!,
            siteContact: _siteContactController.text.trim(),
            instructions: _instructionsController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorText = _cleanErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formsAsync = ref.watch(formsListProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(top: 48, bottom: bottomInset),
      child: Material(
        color: kWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kDivider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add Day Job',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add the work completed today before clocking out.',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextMid,
                      height: 1.5,
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD0D0)),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _SheetLabel('Reference'),
                  const SizedBox(height: 8),
                  _SheetField(
                    controller: _referenceController,
                    hintText: 'Enter job reference',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Reference is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _SheetLabel('Form Name'),
                  const SizedBox(height: 8),
                  formsAsync.when(
                    data: (forms) => _FormDropdown(
                      forms: forms,
                      value: _selectedFormName,
                      onChanged: (value, formId) {
                        setState(() {
                          _selectedFormName = value;
                          _selectedFormId = formId;
                        });
                      },
                    ),
                    loading: () => const _DropdownLoading(),
                    error: (error, _) => _DropdownError(
                      message: _cleanErrorMessage(error),
                      onRetry: () => ref.invalidate(formsListProvider),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SheetLabel('Site Contact'),
                  const SizedBox(height: 8),
                  _SheetField(
                    controller: _siteContactController,
                    hintText: 'Enter site contact',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Site contact is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _SheetLabel('Instructions'),
                  const SizedBox(height: 8),
                  _SheetField(
                    controller: _instructionsController,
                    hintText: 'Add job instructions',
                    minLines: 4,
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Instructions are required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF9DBAF8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Job',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormDropdown extends StatelessWidget {
  final List<FormItem> forms;
  final String? value;
  final Function(String?, int?) onChanged;

  const _FormDropdown({
    required this.forms,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,

      items: forms.map((form) {
        return DropdownMenuItem<String>(
          value: form.name,

          onTap: () {
            onChanged(form.name, form.id);
          },

          child: Text(form.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      onChanged: (_) {},

      validator: (selected) {
        if (selected == null || selected.isEmpty) {
          return 'Form name is required';
        }
        return null;
      },

      decoration: InputDecoration(
        hintText: 'Select form',
        filled: true,
        fillColor: kWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownLoading extends StatelessWidget {
  const _DropdownLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDivider),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: kBlue),
      ),
    );
  }
}

class _DropdownError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DropdownError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD8D8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFFC62828)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;

  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.hintText,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: kWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.5),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onOpenForm;

  const _JobCard({required this.job, required this.onOpenForm});
  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);

      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kDivider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: kBlueSoft,
          highlightColor: Colors.transparent,
          onTap: onOpenForm,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Job #${job.jobNo}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusChip(status: job.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job.projectName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextMid,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  job.clientName,
                  style: const TextStyle(fontSize: 12.5, color: kTextLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                const Divider(color: kDivider, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        job.formName,
                        style: const TextStyle(fontSize: 12.5, color: kTextMid),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: kTextLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formatDate(job.scheduledDate),

                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kTextMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 13, color: kTextLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.reference,
                        style: const TextStyle(fontSize: 12, color: kTextLight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onOpenForm,
                    style: TextButton.styleFrom(
                      foregroundColor: kBlue,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Open Form',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
      case 'open':
        return const Color(0xFF0FC47A);
      case 'completed':
      case 'closed':
        return kBlue;
      case 'pending':
      case 'on hold':
      case 'awaiting':
        return const Color(0xFFF5A623);
      default:
        return kTextLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11.5,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool canAddJob;
  final Future<bool> Function()? onAddJob;

  const _EmptyState({required this.canAddJob, this.onAddJob});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline_rounded, size: 48, color: kTextLight),
            const SizedBox(height: 14),
            const Text(
              'No jobs found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextMid,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              canAddJob
                  ? 'Add today\'s completed work before clocking out.'
                  : 'Jobs will appear here once assigned.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kTextLight),
            ),
            if (canAddJob && onAddJob != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAddJob == null ? null : () => onAddJob!(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Day Job'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
