class User {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class Organization {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.createdAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}

class Membership {
  final int id;
  final String role;
  final Organization organization;

  Membership({
    required this.id,
    required this.role,
    required this.organization,
  });

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        id: json['id'] as int,
        role: json['role'] as String,
        organization: Organization.fromJson(
          json['organization'] as Map<String, dynamic>,
        ),
      );
}

class QueueInfo {
  final int id;
  final int organizationId;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final bool isOpen;
  final String ticketPrefix;
  final int nextNumber;
  final int avgServiceMinutes;
  final int waitingCount;
  final int servingCount;
  final int completedToday;
  final String? organizationName;
  final String? organizationSlug;

  QueueInfo({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.slug,
    required this.description,
    required this.isActive,
    required this.isOpen,
    required this.ticketPrefix,
    required this.nextNumber,
    required this.avgServiceMinutes,
    required this.waitingCount,
    required this.servingCount,
    required this.completedToday,
    this.organizationName,
    this.organizationSlug,
  });

  factory QueueInfo.fromJson(Map<String, dynamic> json) => QueueInfo(
        id: json['id'] as int,
        organizationId: json['organization_id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        isOpen: json['is_open'] as bool? ?? true,
        ticketPrefix: json['ticket_prefix'] as String? ?? 'A',
        nextNumber: json['next_number'] as int? ?? 1,
        avgServiceMinutes: json['avg_service_minutes'] as int? ?? 5,
        waitingCount: json['waiting_count'] as int? ?? 0,
        servingCount: json['serving_count'] as int? ?? 0,
        completedToday: json['completed_today'] as int? ?? 0,
        organizationName: json['organization_name'] as String?,
        organizationSlug: json['organization_slug'] as String?,
      );

  int get estimatedWaitMinutes => waitingCount * avgServiceMinutes;
}

class Ticket {
  final int id;
  final int queueId;
  final int number;
  final String displayCode;
  final String customerName;
  final String customerPhone;
  final String status;
  final String createdAt;
  final String? calledAt;
  final String? startedAt;
  final String? completedAt;
  final String notes;
  final int? position;
  final int? estimatedWaitMinutes;

  Ticket({
    required this.id,
    required this.queueId,
    required this.number,
    required this.displayCode,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.createdAt,
    this.calledAt,
    this.startedAt,
    this.completedAt,
    this.notes = '',
    this.position,
    this.estimatedWaitMinutes,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'] as int,
        queueId: json['queue_id'] as int,
        number: json['number'] as int,
        displayCode: json['display_code'] as String,
        customerName: json['customer_name'] as String,
        customerPhone: json['customer_phone'] as String? ?? '',
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        calledAt: json['called_at'] as String?,
        startedAt: json['started_at'] as String?,
        completedAt: json['completed_at'] as String?,
        notes: json['notes'] as String? ?? '',
        position: json['position'] as int?,
        estimatedWaitMinutes: json['estimated_wait_minutes'] as int?,
      );
}

class DashboardStats {
  final int queueId;
  final String queueName;
  final int currentlyWaiting;
  final int currentlyServing;
  final int currentlyCalled;
  final int completedToday;
  final int skippedToday;
  final int cancelledToday;
  final double avgWaitMinutes;
  final double avgServiceMinutes;
  final int? peakHour;
  final double throughputPerHour;
  final int estimatedWaitForNew;
  final List<Ticket> recentTickets;
  final List<Map<String, dynamic>> hourlyCompleted;
  final Map<String, dynamic> statusBreakdown;

  DashboardStats({
    required this.queueId,
    required this.queueName,
    required this.currentlyWaiting,
    required this.currentlyServing,
    required this.currentlyCalled,
    required this.completedToday,
    required this.skippedToday,
    required this.cancelledToday,
    required this.avgWaitMinutes,
    required this.avgServiceMinutes,
    this.peakHour,
    required this.throughputPerHour,
    required this.estimatedWaitForNew,
    required this.recentTickets,
    required this.hourlyCompleted,
    required this.statusBreakdown,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
        queueId: json['queue_id'] as int,
        queueName: json['queue_name'] as String,
        currentlyWaiting: json['currently_waiting'] as int,
        currentlyServing: json['currently_serving'] as int,
        currentlyCalled: json['currently_called'] as int,
        completedToday: json['completed_today'] as int,
        skippedToday: json['skipped_today'] as int,
        cancelledToday: json['cancelled_today'] as int,
        avgWaitMinutes: (json['avg_wait_minutes'] as num).toDouble(),
        avgServiceMinutes: (json['avg_service_minutes'] as num).toDouble(),
        peakHour: json['peak_hour'] as int?,
        throughputPerHour: (json['throughput_per_hour'] as num).toDouble(),
        estimatedWaitForNew: json['estimated_wait_for_new'] as int,
        recentTickets: (json['recent_tickets'] as List<dynamic>)
            .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
            .toList(),
        hourlyCompleted: (json['hourly_completed'] as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        statusBreakdown: Map<String, dynamic>.from(
          json['status_breakdown'] as Map,
        ),
      );
}
