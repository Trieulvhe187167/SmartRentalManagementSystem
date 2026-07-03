class MaintenanceRequest {
  final int? id;
  final String? requestCode;
  final String? roomNumber;
  final String? tenantName;
  final String? title;
  final String? description;
  final String? priority;
  final String? status;
  final String? category;
  final String? requestDate;
  final String? resolvedDate;
  final String? createdAt;

  const MaintenanceRequest({
    this.id,
    this.requestCode,
    this.roomNumber,
    this.tenantName,
    this.title,
    this.description,
    this.priority,
    this.status,
    this.category,
    this.requestDate,
    this.resolvedDate,
    this.createdAt,
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as int?,
      requestCode: json['requestCode'] as String? ?? json['requestNumber'] as String?,
      roomNumber: json['roomNumber'] as String? ??
          (json['room'] as Map<String, dynamic>?)?['roomNumber'] as String?,
      tenantName: json['tenantName'] as String? ??
          (json['tenantProfile'] as Map<String, dynamic>?)?['fullName'] as String? ??
          (json['requesterUser'] as Map<String, dynamic>?)?['username'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      category: json['category'] as String?,
      requestDate: json['requestDate'] as String? ?? json['submittedAt'] as String?,
      resolvedDate: json['resolvedDate'] as String? ?? json['resolvedAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestCode': requestCode,
        'roomNumber': roomNumber,
        'tenantName': tenantName,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status,
        'category': category,
        'requestDate': requestDate,
        'resolvedDate': resolvedDate,
        'createdAt': createdAt,
      };
}

class MaintenanceRequestCreateRequest {
  final String? title;
  final String? description;
  final String? priority;
  final String? category;

  const MaintenanceRequestCreateRequest({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
      };
}

class MaintenanceRequestUpdateRequest {
  final String? title;
  final String? description;
  final String? priority;

  const MaintenanceRequestUpdateRequest({
    required this.title,
    required this.description,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'priority': priority,
      };
}

class MaintenanceUpdate {
  final int? id;
  final String? status;
  final String? notes;
  final String? updatedBy;
  final String? updatedAt;

  const MaintenanceUpdate({
    this.id,
    this.status,
    this.notes,
    this.updatedBy,
    this.updatedAt,
  });

  factory MaintenanceUpdate.fromJson(Map<String, dynamic> json) {
    return MaintenanceUpdate(
      id: json['id'] as int?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'notes': notes,
        'updatedBy': updatedBy,
        'updatedAt': updatedAt,
      };
}

class MaintenanceStatusUpdateRequest {
  final String? notes;

  const MaintenanceStatusUpdateRequest({
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'notes': notes,
      };
}
