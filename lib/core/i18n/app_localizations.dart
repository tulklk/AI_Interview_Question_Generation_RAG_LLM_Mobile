import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Hand-written LocalizationsDelegate — no code-generation required.
// Usage:  context.l10n.dashboard
// ---------------------------------------------------------------------------

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const delegate = _AppLocalizationsDelegate();

  bool get isVi => locale.languageCode == 'vi';

  // ── App ──────────────────────────────────────────────────────────────────
  String get appName => 'HireGen AI';

  // ── Navigation / Shell ───────────────────────────────────────────────────
  String get dashboard        => isVi ? 'Bảng điều khiển' : 'Dashboard';
  String get generateQuestions => isVi ? 'Tạo câu hỏi'    : 'Generate Questions';
  String get history          => isVi ? 'Lịch sử'          : 'History';
  String get knowledgeBase    => isVi ? 'Cơ sở kiến thức'  : 'Knowledge Base';
  String get settings         => isVi ? 'Cài đặt'          : 'Settings';
  String get profile          => isVi ? 'Hồ sơ'            : 'Profile';
  String get mainMenu         => isVi ? 'MENU CHÍNH'        : 'MAIN MENU';
  String get quickCreate      => isVi ? 'Tạo nhanh'         : 'Quick Create';
  String get quickCreateDesc  => isVi
      ? 'Dán mô tả công việc và nhận câu hỏi trong 30 giây'
      : 'Paste a job description and get questions in 30 seconds';
  String get startNow         => isVi ? 'Bắt đầu →'        : 'Start now →';
  String get logout           => isVi ? 'Đăng xuất'         : 'Log out';
  String get lightMode        => isVi ? 'Chế độ sáng'       : 'Light mode';
  String get darkMode         => isVi ? 'Chế độ tối'        : 'Dark mode';

  // ── Greeting ────────────────────────────────────────────────────────────
  String greetingFor(int hour) {
    if (isVi) {
      if (hour < 5)  return 'Chào đêm khuya';
      if (hour < 11) return 'Chào buổi sáng';
      if (hour < 14) return 'Chào buổi trưa';
      if (hour < 18) return 'Chào buổi chiều';
      return 'Chào buổi tối';
    } else {
      if (hour < 5)  return 'Good night';
      if (hour < 11) return 'Good morning';
      if (hour < 14) return 'Good afternoon';
      if (hour < 18) return 'Good afternoon';
      return 'Good evening';
    }
  }

  // ── Dashboard ────────────────────────────────────────────────────────────
  String get dashboardSubtitle =>
      isVi ? 'Đây là những gì đang xảy ra trong hôm nay.'
           : "Here's what's happening with your recruitment toolkit today.";
  String get generateQuestionsBtn => isVi ? 'Tạo câu hỏi'          : 'Generate Questions';
  String get totalJDs             => isVi ? 'Tổng JD đã xử lý'     : 'Total JDs Processed';
  String get questionsGenerated   => isVi ? 'Câu hỏi đã tạo'       : 'Questions Generated';
  String get thisWeek             => isVi ? 'Tuần này'              : 'This Week';
  String get avgQuestionsPerJD    => isVi ? 'TB câu hỏi/JD'        : 'Avg Questions/JD';
  String get weeklyActivity       => isVi ? 'Hoạt động tuần'        : 'Weekly Activity';
  String get questionsThisWeek    => isVi ? 'Câu hỏi tạo trong tuần' : 'Questions generated this week';
  String get byCategory           => isVi ? 'Theo danh mục'         : 'By Category';
  String get questionTypeBreakdown => isVi ? 'Phân loại câu hỏi'   : 'Question type breakdown';
  String get recentActivity       => isVi ? 'Hoạt động gần đây'    : 'Recent Activity';
  String get recentSessions       => isVi ? '5 phiên gần nhất'      : 'Last 5 sessions';
  String get viewAll              => isVi ? 'Xem tất cả'            : 'View all';
  String get trendThisMonth12     => isVi ? '↑ +12% tháng này'     : '↑ +12% this month';
  String get trendThisMonth28     => isVi ? '↑ +28% tháng này'     : '↑ +28% this month';
  String get trendLastWeek4       => isVi ? '↑ +4 so tuần trước'   : '↑ +4 from last week';
  String get trendImprovement     => isVi ? '↑ +0.6 cải thiện'     : '↑ +0.6 improvement';
  String get questions            => isVi ? 'Câu hỏi'              : 'Questions';
  String get jds                  => isVi ? 'JD'                   : 'JDs';
  String get technicalQuestions   => isVi ? 'Kỹ thuật'             : 'Technical';
  String get behavioralQuestions  => isVi ? 'Hành vi'              : 'Behavioral';
  String get systemDesign         => isVi ? 'Thiết kế hệ thống'    : 'System Design';
  String get problemSolving       => isVi ? 'Giải quyết vấn đề'    : 'Problem Solving';
  String get noCandidatesBadge    => isVi ? 'Không có phiên'       : 'No sessions';

  // ── Generate Flow ────────────────────────────────────────────────────────
  String get createAIQuestions  => isVi ? 'Tạo câu hỏi AI'        : 'Create AI Questions';
  String get restoringSession   => isVi ? 'Đang khôi phục phiên...' : 'Restoring session...';

  // Progress badge (floating, when user exits generate flow)
  String get badgePollingPlan      => isVi ? 'Đang tạo plan...'              : 'Creating plan...';
  String get badgePollingQuestions => isVi ? 'Đang tạo câu hỏi...'            : 'Generating questions...';
  String get badgePlanReady        => isVi ? 'Plan sẵn sàng — Nhấn để duyệt'  : 'Plan ready — Tap to review';
  String get badgeQuestionsReady   => isVi ? 'Câu hỏi xong — Nhấn để xem'     : 'Questions ready — Tap to view';
  String get badgeFailed           => isVi ? 'Tạo thất bại — Nhấn để xử lý'   : 'Generation failed — Tap to retry';
  String get badgeDraftSaved       => isVi ? 'Draft đã lưu'                   : 'Draft saved';
  String get badgeProcessing       => isVi ? 'Đang xử lý...'                  : 'Processing...';

  // Step labels
  String get stepInputJD     => isVi ? 'Nhập JD'     : 'Input JD';
  String get stepCreatePlan  => isVi ? 'Tạo Plan'    : 'Create Plan';
  String get stepReviewPlan  => isVi ? 'Review Plan' : 'Review Plan';
  String get stepGenerate    => isVi ? 'Generate'    : 'Generate';
  String get stepResults     => isVi ? 'Kết Quả'    : 'Results';

  List<String> get stepLabels => [
    stepInputJD, stepCreatePlan, stepReviewPlan, stepGenerate, stepResults,
  ];

  // Step 1 – JD Input
  String get jobDescription  => isVi ? 'Mô tả công việc'  : 'Job Description';
  String get aiNote          => isVi ? 'Ghi chú cho AI'   : 'Note for AI';
  String get optional        => isVi ? '(tùy chọn)'       : '(optional)';
  String get pasteJDHint     => isVi
      ? 'Dán mô tả công việc của bạn vào đây...\n\n'
        'Ví dụ:\nChúng tôi đang tìm kiếm một Frontend Developer '
        'Senior với hơn 5 năm kinh nghiệm React, kỹ năng TypeScript '
        'vững chắc và hiểu biết sâu về tối ưu hóa hiệu suất...'
      : 'Paste your job description here...\n\n'
        'Example:\nWe are looking for a Senior Frontend Developer '
        'with 5+ years of React experience, strong TypeScript skills '
        'and deep understanding of performance optimization...';
  String get aiNoteHint      => isVi
      ? 'VD: Tập trung vào System Design, phỏng vấn bằng tiếng Anh, ưu tiên câu hỏi thực tế...'
      : 'E.g.: Focus on System Design, English interview, prioritize practical questions...';
  String get sufficient      => isVi ? 'Đủ độ dài'  : 'Sufficient';
  String get createPlanBtn   => isVi ? 'Tạo Plan'   : 'Create Plan';
  String get minCharsError   => isVi
      ? 'Nhập ít nhất 50 ký tự mô tả công việc.'
      : 'Enter at least 50 characters for the job description.';
  String needMoreChars(int n) =>
      isVi ? 'Cần thêm $n ký tự' : 'Need $n more characters';
  String validationHint(int n) =>
      isVi ? 'Nhập ít nhất 50 ký tự để tiếp tục (còn thiếu $n ký tự).'
           : 'Enter at least 50 characters to continue ($n more needed).';
  String wordCharCount(int words, int chars) =>
      isVi ? '$words từ  ·  $chars ký tự' : '$words words  ·  $chars chars';

  // ── Knowledge Base ───────────────────────────────────────────────────────
  String get uploadFile          => isVi ? 'Tải lên tệp'           : 'Upload File';
  String get uploadFiles         => isVi ? 'Tải lên tệp'           : 'Upload Files';
  String get dropFilesHint       => isVi ? 'PDF, DOCX, DOC, TXT • Tối đa 20MB'
                                         : 'PDF, DOCX, DOC, TXT • Max 20MB';
  String get searchDocs          => isVi ? 'Tìm kiếm tài liệu...'  : 'Search documents...';
  String get noDocuments         => isVi ? 'Chưa có tài liệu nào'  : 'No documents yet';
  String get noDocumentsHint     => isVi
      ? 'Tải lên tài liệu đầu tiên để xây dựng cơ sở kiến thức của bạn'
      : 'Upload your first document to build your knowledge base';
  String get ready               => isVi ? 'Sẵn sàng'              : 'Ready';
  String get processing          => isVi ? 'Đang xử lý'            : 'Processing';
  String get failedStatus        => isVi ? 'Thất bại'              : 'Failed';
  String get pendingStatus       => isVi ? 'Đang chờ'              : 'Pending';
  String get ingestingStatus     => isVi ? 'Đang nhập'             : 'Ingesting';
  String get delete              => isVi ? 'Xóa'                   : 'Delete';
  String get reingest            => isVi ? 'Nhập lại'              : 'Re-ingest';
  String get deleteConfirmTitle  => isVi ? 'Xóa tài liệu?'         : 'Delete document?';
  String get deleteConfirmBody   => isVi
      ? 'Hành động này không thể hoàn tác.'
      : 'This action cannot be undone.';
  String get cancel              => isVi ? 'Hủy'                   : 'Cancel';
  String get confirm             => isVi ? 'Xác nhận'              : 'Confirm';

  // ── History ──────────────────────────────────────────────────────────────
  String get sessionHistory   => isVi ? 'Lịch sử phiên'       : 'Session History';
  String get allSessions      => isVi ? 'Tất cả'              : 'All';
  String get completed        => isVi ? 'Hoàn thành'          : 'Completed';
  String get draft            => isVi ? 'Nháp'                : 'Draft';
  String get failed           => isVi ? 'Thất bại'            : 'Failed';
  String get inProgress       => isVi ? 'Đang xử lý'          : 'In Progress';
  String get noHistory        => isVi ? 'Chưa có lịch sử'     : 'No history yet';
  String get noHistoryHint    => isVi
      ? 'Tạo phiên câu hỏi đầu tiên của bạn để bắt đầu'
      : 'Create your first question session to get started';
  String get createFirst      => isVi ? 'Tạo phiên đầu tiên'  : 'Create first session';
  String questionsCount(int n) => isVi ? '$n câu hỏi' : '$n questions';
  String get viewDetail       => isVi ? 'Xem chi tiết'        : 'View Detail';
  String get deleteSession    => isVi ? 'Xóa phiên'           : 'Delete Session';
  String get searchSessions   => isVi ? 'Tìm kiếm phiên...'  : 'Search sessions...';
  String get filterBy         => isVi ? 'Lọc theo'            : 'Filter by';
  String get noMatchSessions  => isVi ? 'Không tìm thấy phiên phù hợp'
                                      : 'No matching sessions found';

  // History Detail
  String get sessionDetail    => isVi ? 'Chi tiết phiên'      : 'Session Detail';
  String get saveDraft        => isVi ? 'Lưu nháp'            : 'Save Draft';
  String get generateMore     => isVi ? 'Tạo thêm câu hỏi'   : 'Generate More';
  String get exportQuestions  => isVi ? 'Xuất câu hỏi'        : 'Export Questions';
  String get questionList     => isVi ? 'Danh sách câu hỏi'   : 'Question List';
  String get noQuestions      => isVi ? 'Chưa có câu hỏi nào' : 'No questions yet';

  // ── Settings ─────────────────────────────────────────────────────────────
  String get profileTab        => isVi ? 'Hồ sơ'              : 'Profile';
  String get preferencesTab    => isVi ? 'Tùy chọn'           : 'Preferences';
  String get notificationsTab  => isVi ? 'Thông báo'          : 'Notifications';
  String get securityTab       => isVi ? 'Bảo mật'            : 'Security';
  String get billingTab        => isVi ? 'Thanh toán'         : 'Billing';
  String get save              => isVi ? 'Lưu'                : 'Save';
  String get saving            => isVi ? 'Đang lưu...'        : 'Saving...';
  String get language          => isVi ? 'Ngôn ngữ'           : 'Language';
  String get theme             => isVi ? 'Giao diện'          : 'Theme';
  String get systemTheme       => isVi ? 'Theo hệ thống'      : 'System theme';
  String get fullName          => isVi ? 'Họ và tên'          : 'Full Name';
  String get company           => isVi ? 'Công ty'            : 'Company';
  String get jobTitle          => isVi ? 'Chức danh'          : 'Job Title';
  String get phoneNumber       => isVi ? 'Số điện thoại'      : 'Phone Number';
  String get currentPassword   => isVi ? 'Mật khẩu hiện tại' : 'Current Password';
  String get newPassword       => isVi ? 'Mật khẩu mới'       : 'New Password';
  String get confirmPassword   => isVi ? 'Xác nhận mật khẩu' : 'Confirm Password';
  String get changePassword    => isVi ? 'Đổi mật khẩu'      : 'Change Password';
  String get saveChanges       => isVi ? 'Lưu thay đổi'       : 'Save Changes';

  // ── Jobseeker Shell / Nav ─────────────────────────────────────────────────
  String get candidateSection  => isVi ? 'Ứng viên'           : 'Candidate';
  String get practiceNow       => isVi ? 'Luyện tập ngay'     : 'Practice Now';
  String get practiceHistory   => isVi ? 'Lịch sử luyện tập' : 'Practice History';
  String get myProfile         => isVi ? 'Hồ sơ của tôi'     : 'My Profile';
  String get readyToPractice   => isVi ? 'Sẵn sàng luyện tập?' : 'Ready to Practice?';
  String get readyToPracticeDesc =>
      isVi ? 'Chọn bộ câu hỏi và bắt đầu phỏng vấn thử'
           : 'Pick a question set and start a mock interview';
  String get browseSets        => isVi ? 'Xem bộ câu hỏi →'  : 'Browse Sets →';
  String get notificationTitle => isVi ? 'Thông báo'          : 'Notifications';

  // ── Jobseeker Dashboard ───────────────────────────────────────────────────
  String get dashboardGreetingSubtitle =>
      isVi ? 'Bạn có 3 bộ câu hỏi được đề xuất và chuỗi 7 ngày luyện tập. Tiếp tục phát huy!'
           : 'You have 3 recommended sets and a 7-day practice streak. Keep it up!';
  String get practiceSessions  => isVi ? 'Buổi luyện tập'     : 'Practice Sessions';
  String get averageScore      => isVi ? 'Điểm trung bình'    : 'Average Score';
  String get practiceStreak    => isVi ? 'Chuỗi luyện tập'    : 'Practice Streak';
  String get interviewReadiness => isVi ? 'Mức độ sẵn sàng'  : 'Interview Readiness';
  String get thisWeekStat      => isVi ? '+3 tuần này'         : '+3 this week';
  String get vsLastWeek        => isVi ? '+4% so tuần trước'  : '+4% vs last week';
  String get personalBest      => isVi ? 'Tốt nhất cá nhân'   : 'Personal best';
  String get aiAssessed        => isVi ? 'AI đánh giá'        : 'AI assessed';
  String get highReadiness     => isVi ? 'Cao'                : 'High';
  String get sevenDays         => isVi ? '7 ngày'             : '7 days';
  String get performanceAnalytics => isVi ? 'Phân tích hiệu suất' : 'Performance Analytics';
  String get recentPractice    => isVi ? 'Luyện tập gần đây'  : 'Recent Practice';
  String get latestSessions    => isVi ? 'Các buổi gần nhất'  : 'Your latest sessions';
  String get viewAllHistory    => isVi ? 'Xem tất cả →'       : 'View all →';
  String get strongestSkills   => isVi ? 'Kỹ năng mạnh nhất'  : 'Strongest Skills';
  String get areasToImprove    => isVi ? 'Cần cải thiện'      : 'Areas to Improve';
  String get aiRecommendation  => isVi ? 'Đề xuất AI'         : 'AI Recommendation';
  String get aiRecommendationBody =>
      isVi ? 'Dựa trên các buổi luyện tập gần đây, hãy tập trung vào câu hỏi Tình huống — điểm của bạn ở danh mục này thấp hơn 12% so với điểm Kỹ thuật. Thử bộ câu hỏi Google PM để luyện tư duy có cấu trúc.'
           : 'Based on your recent sessions, focus on Situational questions — your score in this category is 12% below your Technical average. Try the Google PM set to practice structured thinking.';
  String get startPractice     => isVi ? 'Bắt đầu luyện tập' : 'Start Practice';
  String get recommendedForYou => isVi ? 'Đề xuất cho bạn'    : 'Recommended for You';
  String get recommendedSubtitle =>
      isVi ? 'Bộ câu hỏi được AI chọn lọc dựa trên mục tiêu của bạn'
           : 'AI-curated sets based on your target role';
  String get browseAll         => isVi ? 'Xem tất cả →'       : 'Browse all →';
  String get retry_            => isVi ? 'Thử lại'            : 'Retry';

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get aiPoweredBadge    => isVi ? 'Luyện tập phỏng vấn bằng AI' : 'AI-Powered Interview Practice';
  String get marketplaceTitle1 => isVi ? 'Chinh phục'         : 'Ace Your Next';
  String get marketplaceTitle2 => isVi ? 'Phỏng vấn kỹ thuật' : 'Tech Interview';
  String get marketplaceSubtitle =>
      isVi ? 'Luyện tập với bộ câu hỏi phỏng vấn thực tế, nhận phản hồi AI tức thì và theo dõi tiến độ của bạn.'
           : 'Practice with real interview question sets, get instant AI feedback, and track your progress over time.';
  String get startPracticingFree => isVi ? 'Bắt đầu luyện tập miễn phí' : 'Start Practicing Free';
  String get noCreditCard      => isVi ? 'Không cần thẻ tín dụng' : 'No credit card required';
  String get searchSetsHint    => isVi ? 'Tìm theo vai trò, công ty hoặc kỹ năng...' : 'Search by role, company, or skill...';
  String setsFound(int n)      => isVi ? 'Tìm thấy $n bộ câu hỏi' : '$n question sets found';
  String get noSetsFound       => isVi ? 'Không tìm thấy bộ câu hỏi...' : 'No question sets found...';
  String get allCategories     => isVi ? 'Tất cả'             : 'All';
  String get attemptsSuffix    => isVi ? ' lần thử'           : ' attempts';

  // ── Set Detail ────────────────────────────────────────────────────────────
  String get backToSets        => isVi ? '← Quay lại bộ câu hỏi' : '← Back to Question Sets';
  String get questionPreview   => isVi ? 'Xem trước câu hỏi' : 'Question Preview';
  String get skillsCovered     => isVi ? 'Kỹ năng bao gồm'   : 'Skills covered';
  String get sessionOverview   => isVi ? 'Tổng quan phiên'   : 'Session Overview';
  String get totalQuestions    => isVi ? 'Tổng số câu hỏi'   : 'Total Questions';
  String get estimatedTime     => isVi ? 'Thời gian dự kiến' : 'Estimated Time';
  String get difficulty        => isVi ? 'Độ khó'            : 'Difficulty';
  String get targetScore       => isVi ? 'Điểm mục tiêu'     : 'Target Score';
  String get skills            => isVi ? 'Kỹ năng'           : 'Skills';
  String nQuestionsInCategory(String cat, int n) =>
      isVi ? '$cat · $n câu hỏi' : '$cat · $n questions';

  // ── Difficulty & Category labels ──────────────────────────────────────────
  String get easy              => isVi ? 'Dễ'                 : 'Easy';
  String get medium            => isVi ? 'Trung bình'         : 'Medium';
  String get hard              => isVi ? 'Khó'                : 'Hard';
  String get technical         => isVi ? 'Kỹ thuật'           : 'Technical';
  String get behavioral        => isVi ? 'Hành vi'            : 'Behavioral';
  String get situational       => isVi ? 'Tình huống'         : 'Situational';
  String get excellent         => isVi ? 'Xuất sắc'           : 'Excellent';
  String get good              => isVi ? 'Tốt'                : 'Good';
  String get fair              => isVi ? 'Khá'                : 'Fair';
  String get needsWork         => isVi ? 'Cần cải thiện'      : 'Needs Work';

  // ── Practice Session ──────────────────────────────────────────────────────
  String questionNofTotal(int n, int total) =>
      isVi ? 'Câu hỏi $n / $total' : 'Question $n of $total';
  String get answerPlaceholder =>
      isVi ? 'Nhập câu trả lời của bạn ở đây. Hãy cụ thể...'
           : 'Type your answer here. Be specific...';
  String get submitAnswer      => isVi ? 'Gửi câu trả lời'   : 'Submit Answer';
  String get evaluating_       => isVi ? 'AI đang đánh giá câu trả lời...' : 'AI is evaluating your answer...';
  String get answerSubmitted   => isVi ? 'Câu trả lời đã gửi' : 'Answer submitted';
  String get finishGetFeedback => isVi ? 'Hoàn thành & Nhận phản hồi' : 'Finish & Get Feedback';
  String get previous          => isVi ? 'Trước'              : 'Previous';
  String get exitPractice      => isVi ? 'Thoát luyện tập?'  : 'Exit practice?';
  String get exitPracticeBody  =>
      isVi ? 'Tiến độ trong phiên này sẽ bị mất nếu bạn thoát.'
           : 'Your progress in this session will be lost if you exit.';
  String get exit              => isVi ? 'Thoát'              : 'Exit';
  String get stay              => isVi ? 'Ở lại'              : 'Stay';
  String charsCount(int n)     => isVi ? '$n ký tự' : '$n characters';
  String get charsRecommended  => isVi ? ' · Nên nhập 150+ ký tự' : ' · 150+ recommended';

  // ── Feedback / Result ─────────────────────────────────────────────────────
  String get overallScore      => isVi ? 'Điểm tổng quát'    : 'Overall Score';
  String get aiFeedbackTitle   => isVi ? 'Phản hồi AI'       : 'AI Feedback';
  String get aiInsight         => isVi ? 'Nhận xét AI'       : 'AI Insight';
  String get skillBreakdown    => isVi ? 'Phân tích kỹ năng' : 'Skill Breakdown';
  String get questionReview    => isVi ? 'Xem lại từng câu hỏi' : 'Question-by-Question Review';
  String get yourAnswer        => isVi ? 'Câu trả lời của bạn' : 'Your Answer';
  String get strengths         => isVi ? 'Điểm mạnh'         : 'Strengths';
  String get areasToImprove_   => isVi ? 'Cần cải thiện'     : 'Areas to Improve';
  String get aiSuggestion      => isVi ? 'Gợi ý của AI'      : 'AI Suggestion';
  String get practiceAgain     => isVi ? 'Luyện tập lại'     : 'Practice Again';
  String get shareResult       => isVi ? 'Chia sẻ kết quả'   : 'Share Result';
  String get backToHistory     => isVi ? '← Quay lại lịch sử' : '← Back to History';
  String aiInsightForScore(int score) {
    if (score >= 80) {
      return isVi
          ? 'Hiệu suất xuất sắc! Câu trả lời của bạn thể hiện chiều sâu, cấu trúc và ví dụ cụ thể. Bạn đã sẵn sàng cho vòng phỏng vấn thực tế.'
          : 'Outstanding performance! Your answers showed depth, structure, and concrete examples. You\'re ready for real interviews.';
    } else if (score >= 65) {
      return isVi
          ? 'Hiệu suất tốt. Câu trả lời kỹ thuật của bạn mạnh, nhưng câu trả lời hành vi có thể được cải thiện với cấu trúc STAR rõ ràng hơn.'
          : 'Solid performance. Your technical answers were strong, but behavioral responses could benefit from clearer STAR structure.';
    } else {
      return isVi
          ? 'Khởi đầu tốt! Hãy tập trung vào việc cung cấp ví dụ cụ thể hơn và kết quả có thể đo lường được.'
          : 'Good start! Focus on providing more specific examples and quantifiable outcomes.';
    }
  }

  // ── History (jobseeker) ───────────────────────────────────────────────────
  String get totalSessions     => isVi ? 'Tổng buổi luyện tập' : 'Total Sessions';
  String get bestScore         => isVi ? 'Điểm cao nhất'       : 'Best Score';
  String get timePracticed     => isVi ? 'Thời gian luyện tập' : 'Time Practiced';
  String get searchByCompany   => isVi ? 'Tìm theo công ty hoặc vai trò...' : 'Search by company or role...';
  String get allTime           => isVi ? 'Tất cả thời gian'    : 'All Time';
  String get thisWeekFilter    => isVi ? 'Tuần này'            : 'This Week';
  String get thisMonthFilter   => isVi ? 'Tháng này'           : 'This Month';
  String get viewSession       => isVi ? 'Xem'                 : 'View';
  String get retrySession      => isVi ? 'Thử lại'             : 'Retry';
  String get noSessions        => isVi ? 'Chưa có buổi luyện tập nào.' : 'No practice sessions yet.';
  String get noSessionsAction  => isVi ? 'Bắt đầu luyện tập ngay!' : 'Start practicing now!';
  String get session           => isVi ? 'Phiên'               : 'Session';
  String get date              => isVi ? 'Ngày'                : 'Date';
  String get score             => isVi ? 'Điểm'                : 'Score';
  String get duration          => isVi ? 'Thời gian'           : 'Duration';
  String get actions           => isVi ? 'Hành động'           : 'Actions';

  // ── Jobseeker Profile ─────────────────────────────────────────────────────
  String get editProfile       => isVi ? 'Chỉnh sửa hồ sơ'   : 'Edit Profile';
  String get saveChanges_      => isVi ? 'Lưu thay đổi'       : 'Save Changes';
  String get cancelEdit        => isVi ? 'Hủy'                : 'Cancel';
  String get contactInfo       => isVi ? 'Thông tin liên hệ'  : 'Contact Information';
  String get careerGoals       => isVi ? 'Mục tiêu nghề nghiệp' : 'Career Goals';
  String get skillsExpertise   => isVi ? 'Kỹ năng & Chuyên môn' : 'Skills & Expertise';
  String get socialLinks       => isVi ? 'Liên kết mạng xã hội' : 'Social Links';
  String get targetRole        => isVi ? 'Vị trí mục tiêu'   : 'Target Role';
  String get seniorityLevel    => isVi ? 'Cấp độ'             : 'Seniority Level';
  String get bio               => isVi ? 'Giới thiệu bản thân' : 'Bio';
  String get bioHint           => isVi ? 'Giới thiệu về bản thân và mục tiêu nghề nghiệp...' : 'Tell us about your background and career goals...';
  String get targetRoleHint    => isVi ? 'vd. Senior Frontend Developer' : 'e.g. Senior Frontend Developer';
  String get selectLevel       => isVi ? 'Chọn cấp độ'       : 'Select level';
  String get linkedInUrl       => isVi ? 'LinkedIn URL'       : 'LinkedIn URL';
  String get githubUrl         => isVi ? 'GitHub URL'         : 'GitHub URL';
  String get addSkill          => isVi ? 'Thêm kỹ năng'       : 'Add skill';
  String get skillHint         => isVi ? 'vd. React, Python'  : 'e.g. React, Python';
  String get notSet            => isVi ? 'Chưa cập nhật'      : 'Not set';
  String get freePlan          => isVi ? 'Miễn phí'           : 'Free';
  String get profileSaved      => isVi ? 'Hồ sơ đã lưu thành công.' : 'Profile saved successfully.';
  String get profileSaveError  => isVi ? 'Không thể lưu hồ sơ. Vui lòng thử lại.' : 'Could not save profile. Please try again.';
  String get loadingProfile    => isVi ? 'Đang tải hồ sơ...' : 'Loading profile...';
  String get emailNote         => isVi ? 'Email được liên kết với tài khoản và không thể thay đổi ở đây.' : 'Email is linked to your account and cannot be changed here.';
  String get achievements      => isVi ? 'Thành tích'         : 'Achievements';
  String get earned            => isVi ? 'Đã đạt'             : 'Earned';
  String earnedCount(int n, int total) => isVi ? '$n/$total Đã đạt' : '$n/$total Earned';
  String get streak            => isVi ? 'Chuỗi ngày'         : 'Streak';
  String get avatarUpload      => isVi ? 'Tải ảnh lên'        : 'Upload Photo';
  String get imageTooLarge     => isVi ? 'Ảnh quá lớn (tối đa 2MB)' : 'Image too large (max 2MB)';

  // ── Jobseeker Settings ────────────────────────────────────────────────────
  String get settingsTitle     => isVi ? 'Cài đặt'            : 'Settings';
  String get settingsSubtitle  => isVi ? 'Quản lý tùy chọn tài khoản và quyền riêng tư' : 'Manage your account preferences and privacy';
  String get languageSection   => isVi ? 'Ngôn ngữ'           : 'Language';
  String get languageDesc      => isVi ? 'Chọn ngôn ngữ hiển thị ưa thích' : 'Choose your preferred display language';
  String get english           => isVi ? 'English'            : 'English';
  String get vietnamese        => isVi ? 'Tiếng Việt'         : 'Tiếng Việt';
  String get appearanceSection => isVi ? 'Giao diện'          : 'Appearance';
  String get lightTheme        => isVi ? 'Sáng'               : 'Light';
  String get darkTheme         => isVi ? 'Tối'                : 'Dark';
  String get systemTheme_      => isVi ? 'Theo hệ thống'      : 'System';
  String get notificationsSection => isVi ? 'Thông báo'       : 'Notifications';
  String get emailReminders    => isVi ? 'Nhắc nhở luyện tập qua email' : 'Email reminders for practice streaks';
  String get weeklyProgress    => isVi ? 'Tóm tắt tiến độ hàng tuần' : 'Weekly progress summaries';
  String get aiTips            => isVi ? 'Mẹo phỏng vấn AI'  : 'AI interview tips and insights';
  String get privacySection    => isVi ? 'Quyền riêng tư & Dữ liệu' : 'Privacy & Data';
  String get downloadData      => isVi ? 'Tải xuống dữ liệu của tôi' : 'Download my data';
  String get deleteHistory     => isVi ? 'Xóa lịch sử luyện tập' : 'Delete practice history';
  String get deleteAccount     => isVi ? 'Xóa tài khoản'     : 'Delete account';

  // ── Common ───────────────────────────────────────────────────────────────
  String get loading      => isVi ? 'Đang tải...'      : 'Loading...';
  String get error        => isVi ? 'Lỗi'              : 'Error';
  String get retry        => isVi ? 'Thử lại'          : 'Retry';
  String get back         => isVi ? 'Quay lại'         : 'Back';
  String get next         => isVi ? 'Tiếp theo'        : 'Next';
  String get done         => isVi ? 'Xong'             : 'Done';
  String get search       => isVi ? 'Tìm kiếm'         : 'Search';
  String get refresh      => isVi ? 'Làm mới'          : 'Refresh';
  String get createdAt    => isVi ? 'Ngày tạo'         : 'Created at';
  String get by           => isVi ? 'bởi'              : 'by';
  String get min          => isVi ? 'phút'             : 'min';
}

// ── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'vi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ── Extension for ergonomic access ───────────────────────────────────────────

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
