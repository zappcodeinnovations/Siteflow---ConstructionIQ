import 'package:euro_side/modules/templates/model/template_model.dart';
import 'package:euro_side/modules/templates/provider/template_provider.dart';
import 'package:euro_side/modules/templates/view/template_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectTemplateScreen extends ConsumerStatefulWidget {
  final int projectId;
  const ProjectTemplateScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectTemplateScreen> createState() =>
      _ProjectTemplateScreenState();
}

class _ProjectTemplateScreenState extends ConsumerState<ProjectTemplateScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(projectTemplateControllerProvider.notifier).fetchTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectTemplateControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Templates"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FC),
      body: _buildBody(state),
    );
  }

  /// ✅ MAIN BODY
  Widget _buildBody(state) {
    /// 🔄 LOADING
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /// ❌ ERROR
    if (state.error != null && state.error!.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(projectTemplateControllerProvider.notifier)
                    .fetchTemplates();
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    /// 📭 EMPTY
    if (state.templates.isEmpty) {
      return const Center(child: Text("No Templates Found"));
    }

    /// ✅ LIST (filtered by projectId)
    final filteredTemplates = state.templates
        .where((t) => t.projectId == widget.projectId)
        .toList();
    if (filteredTemplates.isEmpty) {
      return const Center(child: Text("No Template Found For This Project"));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(projectTemplateControllerProvider.notifier)
            .fetchTemplates();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: filteredTemplates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final ProjectTemplateModel item = filteredTemplates[index];
          return _templateCard(item);
        },
      ),
    );
  }

  /// 🎨 TEMPLATE CARD UI
  Widget _templateCard(ProjectTemplateModel item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          debugPrint("Clicked Template ID: \\${item.templateId}");
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TemplateFormScreen(template: item),
            ),
          );
          if (result == true && context.mounted) {
            Navigator.of(
              context,
            ).pop(true); // Signal success to parent (for clock out)
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEEF3FF),
                    child: const Icon(
                      Icons.assignment,
                      color: Color(0xFF1B5EF7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.projectName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B2A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statusChip(item.projectStatus),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.description,
                    size: 18,
                    color: Color(0xFF4B5A6E),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.templateName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5A6E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.code, size: 16, color: Color(0xFF9AA8BA)),
                  const SizedBox(width: 4),
                  Text(
                    item.projectCode,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9AA8BA),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.person, size: 16, color: Color(0xFF9AA8BA)),
                  const SizedBox(width: 4),
                  Text(
                    item.clientName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9AA8BA),
                    ),
                  ),
                ],
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5A6E),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF9AA8BA),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 STATUS CHIP
  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 🎨 STATUS COLOR
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green;
      case "planning":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
