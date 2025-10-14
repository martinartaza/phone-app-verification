class SyncResponse {
  final String status;
  final String message;
  final SyncVersion version;
  final String timestamp;
  final String lastUpdate;
  final SyncPolling? polling;
  final SyncData? data;
  final SyncPagination? pagination;

  SyncResponse({
    required this.status,
    required this.message,
    required this.version,
    required this.timestamp,
    required this.lastUpdate,
    this.polling,
    this.data,
    this.pagination,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      status: json['status'] ?? 'success',
      message: json['message'] ?? '',
      version: SyncVersion.fromJson(json['version'] ?? {}),
      timestamp: json['timestamp'] ?? '',
      lastUpdate: json['last_update'] ?? '',
      polling: json['polling'] != null 
          ? SyncPolling.fromJson(json['polling']) 
          : null,
      data: json['data'] != null 
          ? SyncData.fromJson(json['data']) 
          : null,
      pagination: json['pagination'] != null 
          ? SyncPagination.fromJson(json['pagination']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'version': version.toJson(),
      'timestamp': timestamp,
      'last_update': lastUpdate,
      'polling': polling?.toJson(),
      'data': data?.toJson(),
      'pagination': pagination?.toJson(),
    };
  }

  bool get isSuccess => status == 'success';
  bool get hasPolling => polling != null;
  bool get hasData => data != null;
  bool get hasPagination => pagination != null;
}

class SyncVersion {
  final String global;
  final String network;
  final String fulbitos;

  SyncVersion({
    required this.global,
    required this.network,
    required this.fulbitos,
  });

  factory SyncVersion.fromJson(Map<String, dynamic> json) {
    return SyncVersion(
      global: json['global'] ?? '',
      network: json['network'] ?? '',
      fulbitos: json['fulbitos'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'global': global,
      'network': network,
      'fulbitos': fulbitos,
    };
  }
}

class SyncPolling {
  final bool needsPolling;
  final int nextPollSeconds;
  final String reason;
  final List<SyncCriticalEvent> criticalEvents;

  SyncPolling({
    required this.needsPolling,
    required this.nextPollSeconds,
    required this.reason,
    required this.criticalEvents,
  });

  factory SyncPolling.fromJson(Map<String, dynamic> json) {
    return SyncPolling(
      needsPolling: json['needs_polling'] ?? false,
      nextPollSeconds: json['next_poll_seconds'] ?? 600,
      reason: json['reason'] ?? 'default',
      criticalEvents: (json['critical_events'] as List<dynamic>?)
          ?.map((e) => SyncCriticalEvent.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'needs_polling': needsPolling,
      'next_poll_seconds': nextPollSeconds,
      'reason': reason,
      'critical_events': criticalEvents.map((e) => e.toJson()).toList(),
    };
  }

  bool get isFulbitoActive => reason == 'fulbito_active';
  bool get isFulbitoOpening => reason == 'fulbito_opening';
  bool get isDefault => reason == 'default';
}

class SyncCriticalEvent {
  final String type;
  final int fulbitoId;
  final int secondsUntil;

  SyncCriticalEvent({
    required this.type,
    required this.fulbitoId,
    required this.secondsUntil,
  });

  factory SyncCriticalEvent.fromJson(Map<String, dynamic> json) {
    return SyncCriticalEvent(
      type: json['type'] ?? '',
      fulbitoId: json['fulbito_id'] ?? 0,
      secondsUntil: json['seconds_until'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'fulbito_id': fulbitoId,
      'seconds_until': secondsUntil,
    };
  }

  bool get isRegistrationOpening => type == 'registration_opening';
  bool get isRegistrationActive => type == 'registration_active';
}

class SyncData {
  final SyncNetworkData? network;
  final SyncFulbitosData? fulbitos;
  final SyncNotificationsData? notifications;

  SyncData({
    this.network,
    this.fulbitos,
    this.notifications,
  });

  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      network: json['network'] != null 
          ? SyncNetworkData.fromJson(json['network']) 
          : null,
      fulbitos: json['fulbitos'] != null 
          ? SyncFulbitosData.fromJson(json['fulbitos']) 
          : null,
      notifications: json['notifications'] != null 
          ? SyncNotificationsData.fromJson(json['notifications']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'network': network?.toJson(),
      'fulbitos': fulbitos?.toJson(),
      'notifications': notifications?.toJson(),
    };
  }
}

class SyncNetworkData {
  final String version;
  final bool changed;
  final List<Map<String, dynamic>> connections;
  final List<Map<String, dynamic>> pendingReceived;
  final List<Map<String, dynamic>> pendingSent;
  final int totalConnections;
  final int totalPendingReceived;
  final int totalPendingSent;

  SyncNetworkData({
    required this.version,
    required this.changed,
    required this.connections,
    required this.pendingReceived,
    required this.pendingSent,
    required this.totalConnections,
    required this.totalPendingReceived,
    required this.totalPendingSent,
  });

  factory SyncNetworkData.fromJson(Map<String, dynamic> json) {
    return SyncNetworkData(
      version: json['version'] ?? '',
      changed: json['changed'] ?? false,
      connections: (json['connections'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      pendingReceived: (json['pending_received'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      pendingSent: (json['pending_sent'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      totalConnections: json['total_connections'] ?? 0,
      totalPendingReceived: json['total_pending_received'] ?? 0,
      totalPendingSent: json['total_pending_sent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'changed': changed,
      'connections': connections,
      'pending_received': pendingReceived,
      'pending_sent': pendingSent,
      'total_connections': totalConnections,
      'total_pending_received': totalPendingReceived,
      'total_pending_sent': totalPendingSent,
    };
  }
}

class SyncFulbitosData {
  final String version;
  final bool changed;
  final List<Map<String, dynamic>> myFulbitos;
  final List<Map<String, dynamic>> memberFulbitos;
  final List<Map<String, dynamic>> pendingInvitations;
  final int totalMyFulbitos;
  final int totalMemberFulbitos;
  final int totalPendingInvitations;
  final int? nextCriticalEventSeconds;

  SyncFulbitosData({
    required this.version,
    required this.changed,
    required this.myFulbitos,
    required this.memberFulbitos,
    required this.pendingInvitations,
    required this.totalMyFulbitos,
    required this.totalMemberFulbitos,
    required this.totalPendingInvitations,
    this.nextCriticalEventSeconds,
  });

  factory SyncFulbitosData.fromJson(Map<String, dynamic> json) {
    return SyncFulbitosData(
      version: json['version'] ?? '',
      changed: json['changed'] ?? false,
      myFulbitos: (json['my_fulbitos'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      memberFulbitos: (json['member_fulbitos'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      pendingInvitations: (json['pending_invitations'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>() ?? [],
      totalMyFulbitos: json['total_my_fulbitos'] ?? 0,
      totalMemberFulbitos: json['total_member_fulbitos'] ?? 0,
      totalPendingInvitations: json['total_pending_invitations'] ?? 0,
      nextCriticalEventSeconds: json['next_critical_event_seconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'changed': changed,
      'my_fulbitos': myFulbitos,
      'member_fulbitos': memberFulbitos,
      'pending_invitations': pendingInvitations,
      'total_my_fulbitos': totalMyFulbitos,
      'total_member_fulbitos': totalMemberFulbitos,
      'total_pending_invitations': totalPendingInvitations,
      'next_critical_event_seconds': nextCriticalEventSeconds,
    };
  }
}

class SyncNotificationsData {
  final int total;
  final int network;
  final int fulbito;

  SyncNotificationsData({
    required this.total,
    required this.network,
    required this.fulbito,
  });

  factory SyncNotificationsData.fromJson(Map<String, dynamic> json) {
    return SyncNotificationsData(
      total: json['total'] ?? 0,
      network: json['network'] ?? 0,
      fulbito: json['fulbito'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'network': network,
      'fulbito': fulbito,
    };
  }
}

class SyncPagination {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;
  final int totalItems;

  SyncPagination({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
    required this.totalItems,
  });

  factory SyncPagination.fromJson(Map<String, dynamic> json) {
    return SyncPagination(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      pageSize: json['page_size'] ?? 10,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      totalItems: json['total_items'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_pages': totalPages,
      'page_size': pageSize,
      'has_next': hasNext,
      'has_previous': hasPrevious,
      'total_items': totalItems,
    };
  }
}

