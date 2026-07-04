enum FeedbackType { dailyCheckIn, featureRequest, bugReport }

extension FeedbackTypeX on FeedbackType {
  String get value => switch (this) {
    FeedbackType.dailyCheckIn => 'daily_checkin',
    FeedbackType.featureRequest => 'feature_request',
    FeedbackType.bugReport => 'bug_report',
  };

  String get label => switch (this) {
    FeedbackType.dailyCheckIn => 'General',
    FeedbackType.featureRequest => 'Feature request',
    FeedbackType.bugReport => 'Bug report',
  };
}
