// lib/data/models/enums.dart

enum ApplicationStatus {
  pending,
  accepted,
  rejected,
}

enum ProjectStatus {
  open,
  in_progress,
  pending_review,
  completed,
  cancelled,
}

enum UserRole {
  client,
  freelancer,
}

// Extension'lar da güncellenmeli
extension ApplicationStatusExtension on ApplicationStatus {
  String toJson() {
    switch (this) {
      case ApplicationStatus.pending:
        return 'pending';
      case ApplicationStatus.accepted:
        return 'accepted';
      case ApplicationStatus.rejected:
        return 'rejected';
    }
  }

  static ApplicationStatus fromJson(String value) {
    switch (value) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }
}

extension ProjectStatusExtension on ProjectStatus {
  String toJson() {
    switch (this) {
      case ProjectStatus.open:
        return 'open';
      case ProjectStatus.in_progress:
        return 'in_progress';
      case ProjectStatus.pending_review:
        return 'pending_review';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.cancelled:
        return 'cancelled';
    }
  }

  static ProjectStatus fromJson(String value) {
    switch (value) {
      case 'open':
        return ProjectStatus.open;
      case 'in_progress':  // *** DÜZELTME ***
        return ProjectStatus.in_progress;
      case 'completed':
        return ProjectStatus.completed;
      case 'cancelled':
        return ProjectStatus.cancelled;
      default:
        return ProjectStatus.open;
    }
  }
}

extension UserRoleExtension on UserRole {
  String toJson() {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.freelancer:
        return 'freelancer';
    }
  }

  static UserRole fromJson(String value) {
    switch (value) {
      case 'client':
        return UserRole.client;
      case 'freelancer':
        return UserRole.freelancer;
      default:
        return UserRole.freelancer;
    }
  }
}