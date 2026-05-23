import 'package:euroside/modules/Team/model/teammate_model.dart';
import 'package:euroside/services/teammate_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';


class TeammatesPage extends StatelessWidget {
  final int projectId;

  final String projectName;

  const TeammatesPage({
    super.key,

    required this.projectId,

    required this.projectName,
  });

  static const Color _bg = Color(0xffF4F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _bg,

        elevation: 0,

        scrolledUnderElevation: 0,

        title: Text(
          "$projectName Team",

          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: FutureBuilder<List<TeammateModel>>(
        future: TeammateService.getProjectTeammates(projectId),

        builder: (context, snapshot) {
          /// LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ERROR
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load teammates"));
          }

          final teammates = snapshot.data ?? [];

          /// EMPTY
          if (teammates.isEmpty) {
            return const Center(child: Text("No teammates found"));
          }

          /// SUCCESS
          return ListView.builder(
            padding: const EdgeInsets.all(18),

            itemCount: teammates.length,

            itemBuilder: (context, index) {
              final member = teammates[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),

                      blurRadius: 10,

                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    /// AVATAR
                    CircleAvatar(
                      radius: 28,

                      backgroundColor: Colors.blue.shade100,

                      backgroundImage: member.profileImage != null
                          ? NetworkImage(member.profileImage!)
                          : null,

                      child: member.profileImage == null
                          ? Text(
                              member.displayName[0].toUpperCase(),

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,

                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),

                    const SizedBox(width: 16),

                    /// DETAILS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            member.displayName,

                            style: const TextStyle(
                              fontSize: 16,

                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            member.email,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(color: Colors.grey.shade700),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(
                                Iconsax.user,

                                size: 14,

                                color: Colors.grey.shade600,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                member.effectiveRole,

                                style: TextStyle(
                                  color: Colors.grey.shade600,

                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: Duration(milliseconds: index * 120));
            },
          );
        },
      ),
    );
  }
}
