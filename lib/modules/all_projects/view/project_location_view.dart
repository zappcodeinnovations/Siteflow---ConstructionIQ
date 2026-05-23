import 'package:euroside/modules/all_projects/model/all_project_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectLocationPage extends StatelessWidget {
  final AllprojectModel project;

  const ProjectLocationPage({
    super.key,
    required this.project,
  });

  static const Color _bg = Color(0xffF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xff2563EB);
  static const Color _text = Color(0xff0F172A);
  static const Color _subText = Color(0xff64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,

        titleSpacing: 0,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Project Location",
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),

            Text(
              project.name,
              style: const TextStyle(
                color: _subText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            _buildMapCard(context),

            const SizedBox(height: 18),

            // _buildQuickActions(),

            // const SizedBox(height: 24),

            _sectionTitle(
              "Location Details",
              Iconsax.location,
            ),

            const SizedBox(height: 14),

            _buildLocationDetails(),

            const SizedBox(height: 24),

            _sectionTitle(
              "Team Members",
              Iconsax.people,
            ),

            const SizedBox(height: 14),

            _buildTeamSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    final lat = double.tryParse(project.latitude);
    final lng = double.tryParse(project.longitude);

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(28),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(28),

        child: Stack(
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,

              child: lat == null || lng == null
                  ? _mapPlaceholder()
                  : InkWell(
                      onTap: () => _openMap(
                        context,
                        lat,
                        lng,
                      ),

                      child: Hero(
                        tag: "map_${project.id}",

                        child: Image.network(
                          _staticMapUrl(
                            lat,
                            lng,
                          ),

                          fit: BoxFit.cover,

                          errorBuilder:
                              (_, __, ___) =>
                                  _mapPlaceholder(),

                          loadingBuilder:
                              (
                                context,
                                child,
                                progress,
                              ) {
                                if (progress ==
                                    null) {
                                  return child;
                                }

                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              },
                        ),
                      ),
                    ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,

                    colors: [
                      Colors.black
                          .withOpacity(.05),

                      Colors.black
                          .withOpacity(.75),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 20,
              right: 20,
              bottom: 20,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color:
                          Colors.green.shade600,

                      borderRadius:
                          BorderRadius.circular(
                        30,
                      ),
                    ),

                    child: const Text(
                      "LIVE LOCATION",

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    project.name,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    project.locationLabel,

                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(.9),

                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white,

                            foregroundColor:
                                Colors.black,

                            elevation: 0,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 14,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                          ),

                          onPressed:
                              lat == null ||
                                      lng ==
                                          null
                                  ? null
                                  : () => _openMap(
                                        context,
                                        lat,
                                        lng,
                                      ),

                          icon: const Icon(
                            Iconsax.location,
                          ),

                          label: const Text(
                            "Map",
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Container(
                      //   decoration: BoxDecoration(
                      //     color: Colors.white
                      //         .withOpacity(.2),

                      //     borderRadius:
                      //         BorderRadius.circular(
                      //       18,
                      //     ),
                      //   ),

                      //   child: IconButton(
                      //     onPressed: () {},

                      //     icon: const Icon(
                      //       Iconsax.share,
                      //       color: Colors.white,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(
          begin: .2,
          duration: 500.ms,
        );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        "icon": Iconsax.location,
        "title": "Navigate",
        "color": const Color(0xff2563EB),
      },
      {
        "icon": Iconsax.call,
        "title": "Call Team",
        "color": const Color(0xff16A34A),
      },
      {
        "icon": Iconsax.message,
        "title": "Message",
        "color": const Color(0xffEA580C),
      },
      {
        "icon": Iconsax.share,
        "title": "Share",
        "color": const Color(0xff7C3AED),
      },
    ];

    return SizedBox(
      height: 115,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemBuilder: (_, index) {
          final action = actions[index];

          return Container(
            width: 100,

            decoration: BoxDecoration(
              color: _surface,

              borderRadius:
                  BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(.04),

                  blurRadius: 10,
                  offset:
                      const Offset(0, 4),
                ),
              ],
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),

                  decoration: BoxDecoration(
                    color:
                        (action["color"]
                                as Color)
                            .withOpacity(.1),

                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),

                  child: Icon(
                    action["icon"]
                        as IconData,

                    color:
                        action["color"]
                            as Color,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  action["title"]
                      .toString(),

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,

                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ).animate().fade(
                delay: Duration(
                  milliseconds:
                      index * 120,
                ),
              );
        },

        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 14),

        itemCount: actions.length,
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius:
            BorderRadius.circular(26),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  12,
                ),

                decoration: BoxDecoration(
                  color: const Color(
                    0xffEFF6FF,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: const Icon(
                  Iconsax.map,
                  color: _primary,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  "Project Address",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            project.siteAddress.isEmpty
                ? project.locationLabel
                : project.siteAddress,

            style: const TextStyle(
              color: _text,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 12,
            runSpacing: 12,

            children: [
              _infoPill(
                Iconsax.building,
                project.city,
                "City",
              ),

              _infoPill(
                Iconsax.global,
                project.country,
                "Country",
              ),

              _infoPill(
                Iconsax.location,
                project.postalCode,
                "Postal",
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(
          delay: 200.ms,
        );
  }

  Widget _buildTeamSection() {
    return Column(
      children: [
        if (project.teamMembers.isNotEmpty)
          ...project.teamMembers.map(
            (member) => _memberTile(
              member,
            ),
          )
        else
          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: _surface,

              borderRadius:
                  BorderRadius.circular(
                24,
              ),
            ),

            child: Column(
              children: [
                const Icon(
                  Iconsax.people,
                  size: 42,
                  color: _subText,
                ),

                const SizedBox(height: 14),

                Text(
                  project.assignedWorkerCount >
                          0
                      ? "Assigned Workers: ${project.assignedWorkerCount}"
                      : "No team member details available.",

                  textAlign:
                      TextAlign.center,

                  style: const TextStyle(
                    color: _subText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _memberTile(
    ProjectTeamMember member,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xff2563EB),
                  Color(0xff1D4ED8),
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: Center(
              child: Text(
                member.name.isEmpty
                    ? "?"
                    : member.name[0]
                        .toUpperCase(),

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  member.name,

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,

                    fontSize: 16,
                    color: _text,
                  ),
                ),

                if (member.role.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),

                    child: Text(
                      member.role,

                      style: const TextStyle(
                        color: _subText,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),

                if (member.email.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 10,
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.sms,
                          size: 16,
                          color: _primary,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child: Text(
                            member.email,

                            style:
                                const TextStyle(
                              color: _text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (member.phone.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 8,
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.call,
                          size: 16,
                          color: Colors.green,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          member.phone,

                          style:
                              const TextStyle(
                            color: _text,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(
          delay: 300.ms,
        );
  }

  Widget _infoPill(
    IconData icon,
    String value,
    String fallback,
  ) {
    final label =
        value.trim().isEmpty
            ? fallback
            : value;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 18,
            color: _primary,
          ),

          const SizedBox(width: 10),

          Text(
            label,

            style: const TextStyle(
              color: _text,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _subText,
        ),

        const SizedBox(width: 8),

        Text(
          title,

          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
            color: _text,
          ),
        ),
      ],
    );
  }

  Widget _mapPlaceholder() {
    return Container(
      color: const Color(0xffE2E8F0),

      alignment: Alignment.center,

      child: const Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            Iconsax.map,
            size: 42,
            color: _subText,
          ),

          SizedBox(height: 12),

          Text(
            "Map preview not available",

            style: TextStyle(
              color: _subText,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _staticMapUrl(
    double lat,
    double lng,
  ) {
    return "https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=900x400&markers=$lat,$lng,red-pushpin";
  }

  Future<void> _openMap(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    try {
      final launched =
          await launchUrl(
        url,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched &&
          context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text("Could not open map."),
          ),
        );
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Map feature not ready.",
            ),
          ),
        );
      }
    }
  }
}