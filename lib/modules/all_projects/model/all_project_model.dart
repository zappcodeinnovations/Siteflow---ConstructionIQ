class AllprojectModel {
  final int id;
  final String name;
  final String code;
  final String description;
  final String status;
  final String priority;
  final String siteAddress;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String latitude;
  final String longitude;
  final int progress;
  final String startDate;
  final String endDate;
  final String budget;
  final int assignedWorkerCount;
  final int jobCount;
  final ProjectMeta? client;
  final ProjectMeta? template;
  final ProjectMeta? contractor;
  final List<ProjectTeamMember> teamMembers;

  const AllprojectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.status,
    required this.priority,
    required this.siteAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.progress,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.assignedWorkerCount,
    required this.jobCount,
    this.client,
    this.template,
    this.contractor,
    this.teamMembers = const [],
  });

  factory AllprojectModel.fromJson(Map<String, dynamic> json) {
    return AllprojectModel(
      id: _toInt(json['id']),
      name: _toString(json['name'] ?? json['project_name']),
      code: _toString(json['code'] ?? json['project_code']),
      description: _toString(json['description']),
      status: _toString(json['status']),
      priority: _toString(json['priority']),
      siteAddress: _toString(json['site_address']),
      city: _toString(json['city']),
      state: _toString(json['state']),
      country: _toString(json['country']),
      postalCode: _toString(json['postal_code']),
      latitude: _toString(json['latitude']),
      longitude: _toString(json['longitude']),
      progress: _toInt(json['progress']),
      startDate: _toString(json['start_date']),
      endDate: _toString(json['end_date']),
      budget: _toString(json['budget']),
      assignedWorkerCount: _toInt(json['assigned_worker_count']),
      jobCount: _toInt(json['job_count']),
      client: ProjectMeta.fromDynamic(json['client']),
      template: ProjectMeta.fromDynamic(json['template']),
      contractor: ProjectMeta.fromDynamic(json['contractor']),
      teamMembers: _extractTeamMembers(json)
          .map(ProjectTeamMember.fromDynamic)
          .whereType<ProjectTeamMember>()
          .toList(),
    );
  }

  String get locationLabel {
    final parts = [city, state, country]
        .where((value) => value.trim().isNotEmpty)
        .toList();

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return siteAddress.isNotEmpty ? siteAddress : 'Location not available';
  }

  bool get hasCoordinates =>
      double.tryParse(latitude) != null && double.tryParse(longitude) != null;

  static List<dynamic> _extractTeamMembers(Map<String, dynamic> json) {
    const possibleKeys = [
      'team_members',
      'teamMembers',
      'members',
      'project_members',
      'workers',
      'assigned_workers',
      'assigned_worker_details',
      'assigned_workers_details',
    ];

    for (final key in possibleKeys) {
      final value = json[key];
      if (value is List) {
        return value;
      }
    }

    return const [];
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _toString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'status': status,
      'priority': priority,
      'site_address': siteAddress,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'progress': progress,
      'start_date': startDate,
      'end_date': endDate,
      'budget': budget,
      'assigned_worker_count': assignedWorkerCount,
      'job_count': jobCount,
      'client': client?.toJson(),
      'template': template?.toJson(),
      'contractor': contractor?.toJson(),
      'team_members': teamMembers.map((e) => e.toJson()).toList(),
    };
  }
}

class ProjectMeta {
  final int id;
  final String name;
  final String code;
  final String status;

  const ProjectMeta({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  factory ProjectMeta.fromJson(Map<String, dynamic> json) {
    return ProjectMeta(
      id: AllprojectModel._toInt(json['id']),
      name: AllprojectModel._toString(json['name'] ?? json['project_name']),
      code: AllprojectModel._toString(json['code'] ?? json['project_code']),
      status: AllprojectModel._toString(json['status']),
    );
  }

  static ProjectMeta? fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ProjectMeta.fromJson(value);
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status,
    };
  }
}

class ProjectTeamMember {
  final int id;
  final String name;
  final String role;
  final String email;
  final String phone;

  const ProjectTeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
  });

  static ProjectTeamMember? fromDynamic(dynamic value) {
    if (value is String) {
      final trimmedValue = value.trim();
      if (trimmedValue.isEmpty) {
        return null;
      }

      return ProjectTeamMember(
        id: 0,
        name: trimmedValue,
        role: '',
        email: '',
        phone: '',
      );
    }

    if (value is! Map<String, dynamic>) {
      return null;
    }

    final name = _firstNonEmpty([
      value['name'],
      value['full_name'],
      value['worker_name'],
      value['member_name'],
      value['user_name'],
    ]);

    if (name.isEmpty) {
      return null;
    }

    return ProjectTeamMember(
      id: AllprojectModel._toInt(value['id']),
      name: name,
      role: _firstNonEmpty([
        value['role'],
        value['designation'],
        value['position'],
      ]),
      email: _firstNonEmpty([value['email']]),
      phone: _firstNonEmpty([value['phone'], value['mobile']]),
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
    };
  }
}
