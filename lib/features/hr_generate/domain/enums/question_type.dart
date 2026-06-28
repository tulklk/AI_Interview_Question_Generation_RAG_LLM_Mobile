enum HrQuestionType {
  technical,
  behavioral,
  situational,
  systemDesign,
  problemSolving;

  static HrQuestionType fromString(String s) {
    final k = s.toLowerCase().replaceAll(RegExp(r'[-_ ]'), '');
    switch (k) {
      case 'technical':      return HrQuestionType.technical;
      case 'behavioral':     return HrQuestionType.behavioral;
      case 'situational':    return HrQuestionType.situational;
      case 'systemdesign':   return HrQuestionType.systemDesign;
      case 'problemsolving': return HrQuestionType.problemSolving;
      default:               return HrQuestionType.technical;
    }
  }

  String get displayName {
    switch (this) {
      case HrQuestionType.technical:      return 'Technical';
      case HrQuestionType.behavioral:     return 'Behavioral';
      case HrQuestionType.situational:    return 'Situational';
      case HrQuestionType.systemDesign:   return 'System-design';
      case HrQuestionType.problemSolving: return 'Problem-solving';
    }
  }

  String toApiString() {
    switch (this) {
      case HrQuestionType.technical:      return 'technical';
      case HrQuestionType.behavioral:     return 'behavioral';
      case HrQuestionType.situational:    return 'situational';
      case HrQuestionType.systemDesign:   return 'system-design';
      case HrQuestionType.problemSolving: return 'problem-solving';
    }
  }
}
