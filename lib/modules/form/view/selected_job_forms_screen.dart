import 'package:euroside/modules/form/model/form_model.dart';
import 'package:euroside/modules/form/provider/form_provider.dart';
import 'package:euroside/modules/form/view/form.dart';
import 'package:euroside/network/api_endpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedJobFormsScreen extends ConsumerWidget {
  final int jobId;
  final String? jobTitle;

  const SelectedJobFormsScreen({super.key, required this.jobId, this.jobTitle});

  Future<void> _openForm(BuildContext context, FormItem form) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    if (token.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to open the form.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormWebViewPage(
          title: form.name,
          endpoint: ApiEndpoints.userFormHtml(form.id),
          accessToken: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formsAsync = ref.watch(selectedJobFormsProvider(jobId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          jobTitle == null || jobTitle!.trim().isEmpty
              ? 'Selected Forms'
              : jobTitle!,
          style: const TextStyle(
            color: Color(0xFF0D1B2A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: formsAsync.when(
        data: (forms) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(selectedJobFormsProvider(jobId));
            await ref.read(selectedJobFormsProvider(jobId).future);
          },
          child: forms.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Color(0xFF9AA8BA),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No selected forms found for this job.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5A6E),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: forms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final form = forms[index];
                    return _SelectedFormCard(
                      form: form,
                      onTap: () => _openForm(context, form),
                    );
                  },
                ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1B5EF7),
            strokeWidth: 2.5,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFF9AA8BA),
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load selected forms',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5A6E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF9AA8BA),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ref.invalidate(selectedJobFormsProvider(jobId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedFormCard extends StatelessWidget {
  final FormItem form;
  final VoidCallback onTap;

  const _SelectedFormCard({required this.form, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF1B5EF7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    if ((form.slug.trim().isNotEmpty ||
                        (form.description ?? '').trim().isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Text(
                        form.slug.trim().isNotEmpty
                            ? form.slug
                            : form.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF4B5A6E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA8BA)),
            ],
          ),
        ),
      ),
    );
  }
}
