enum FocusStatus {
  inactive, // monitoring off
  present,
  absent,
  distracted,
  fatigued,
  error,
}

extension FocusStatusX on FocusStatus {
  String label() => switch (this) {
        FocusStatus.inactive => 'Inactive',
        FocusStatus.present => 'Present',
        FocusStatus.absent => 'Absent',
        FocusStatus.distracted => 'Distracted',
        FocusStatus.fatigued => 'Fatigued',
        FocusStatus.error => 'Error',
      };
}