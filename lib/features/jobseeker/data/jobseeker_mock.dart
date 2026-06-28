import 'package:flutter/material.dart';
import '../models/jobseeker_models.dart';

// ── Company colours (Tailwind → Flutter) ──────────────────────────────────────

const _kBlue    = Color(0xFF3B82F6);
const _kViolet  = Color(0xFF8B5CF6);
const _kEmerald = Color(0xFF10B981);
const _kAmber   = Color(0xFFF59E0B);
const _kRed     = Color(0xFFEF4444);
const _kCyan    = Color(0xFF06B6D4);

// ── Question Sets ─────────────────────────────────────────────────────────────

const questionSets = <QuestionSet>[
  // qs-1 ─ Meta / Senior Frontend
  QuestionSet(
    id: 'qs-1',
    title: 'Senior Frontend Developer Interview',
    company: 'Meta',
    companyInitials: 'M',
    companyColor: _kBlue,
    difficulty: QuestionDifficulty.Hard,
    skills: ['React', 'TypeScript', 'Next.js', 'Performance'],
    totalQuestions: 15,
    estimatedTime: '~45 min',
    category: 'Frontend',
    description:
        'Comprehensive frontend interview prep focusing on React ecosystem, TypeScript, and performance optimization techniques used by top tech companies.',
    rating: 4.8,
    attempts: 1240,
    questions: [
      PracticeQuestion(
        id: 'q1-1',
        text: 'Explain React\'s reconciliation algorithm and how the Virtual DOM works.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Hard,
      ),
      PracticeQuestion(
        id: 'q1-2',
        text: 'How would you optimize a React application that\'s experiencing performance issues?',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Hard,
      ),
      PracticeQuestion(
        id: 'q1-3',
        text: 'Describe your experience with TypeScript generics and when you\'d use them.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q1-4',
        text: 'Tell me about a time you had to refactor a large codebase. What was your approach?',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q1-5',
        text: 'How do you handle disagreements with your team about technical decisions?',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q1-6',
        text: 'You\'re tasked with migrating a large React class component codebase to hooks. How would you approach this?',
        category: QuestionCategory.Situational,
        difficulty: QuestionDifficulty.Hard,
      ),
    ],
  ),

  // qs-2 ─ Stripe / Full Stack
  QuestionSet(
    id: 'qs-2',
    title: 'Full Stack Engineer — Node + React',
    company: 'Stripe',
    companyInitials: 'S',
    companyColor: _kViolet,
    difficulty: QuestionDifficulty.Medium,
    skills: ['Node.js', 'React', 'PostgreSQL', 'REST APIs'],
    totalQuestions: 12,
    estimatedTime: '~35 min',
    category: 'Full Stack',
    description:
        'Full stack interview covering Node.js backend, React frontend, and database design patterns for fintech-level reliability.',
    rating: 4.6,
    attempts: 890,
    questions: [
      PracticeQuestion(
        id: 'q2-1',
        text: 'Explain the event loop in Node.js and how it handles asynchronous operations.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q2-2',
        text: 'How do you design a REST API that handles high traffic and ensures data consistency?',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Hard,
      ),
      PracticeQuestion(
        id: 'q2-3',
        text: 'Describe a challenging full-stack feature you built end-to-end. What were the hardest parts?',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q2-4',
        text: 'A client reports intermittent 500 errors in production. How do you diagnose and fix this?',
        category: QuestionCategory.Situational,
        difficulty: QuestionDifficulty.Hard,
      ),
    ],
  ),

  // qs-3 ─ Google / Product Manager
  QuestionSet(
    id: 'qs-3',
    title: 'Product Manager Interview Prep',
    company: 'Google',
    companyInitials: 'G',
    companyColor: _kEmerald,
    difficulty: QuestionDifficulty.Medium,
    skills: ['Product Strategy', 'Metrics', 'User Research', 'Roadmap'],
    totalQuestions: 10,
    estimatedTime: '~30 min',
    category: 'Product',
    description:
        'Comprehensive PM interview prep covering product strategy, metrics-driven decisions, and case studies used at top product companies.',
    rating: 4.7,
    attempts: 2100,
    questions: [
      PracticeQuestion(
        id: 'q3-1',
        text: 'How would you improve Google Maps for drivers?',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q3-2',
        text: 'Tell me about a product you launched that failed. What did you learn?',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q3-3',
        text: 'You\'re the PM for Gmail. Metrics drop 20% overnight. What do you do?',
        category: QuestionCategory.Situational,
        difficulty: QuestionDifficulty.Hard,
      ),
    ],
  ),

  // qs-4 ─ Amazon / Backend / System Design
  QuestionSet(
    id: 'qs-4',
    title: 'Backend Systems Design',
    company: 'Amazon',
    companyInitials: 'A',
    companyColor: _kAmber,
    difficulty: QuestionDifficulty.Hard,
    skills: ['Java', 'Spring Boot', 'Microservices', 'System Design'],
    totalQuestions: 12,
    estimatedTime: '~40 min',
    category: 'Backend',
    description:
        'System design and backend engineering interview for senior roles, focusing on scalability, distributed systems, and AWS architecture patterns.',
    rating: 4.5,
    attempts: 1560,
    questions: [
      PracticeQuestion(
        id: 'q4-1',
        text: 'Design a URL shortener service that handles 100M requests per day.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Hard,
      ),
      PracticeQuestion(
        id: 'q4-2',
        text: 'Explain the differences between SQL and NoSQL databases and when to use each.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q4-3',
        text: 'Describe your approach to handling a production outage affecting thousands of users.',
        category: QuestionCategory.Situational,
        difficulty: QuestionDifficulty.Hard,
      ),
    ],
  ),

  // qs-5 ─ Netflix / Data Science
  QuestionSet(
    id: 'qs-5',
    title: 'Data Science Interview Essentials',
    company: 'Netflix',
    companyInitials: 'N',
    companyColor: _kRed,
    difficulty: QuestionDifficulty.Medium,
    skills: ['Python', 'SQL', 'Machine Learning', 'Statistics'],
    totalQuestions: 8,
    estimatedTime: '~25 min',
    category: 'Data',
    description:
        'Data science interview prep covering ML concepts, A/B testing, SQL, and statistical analysis used at data-driven companies.',
    rating: 4.4,
    attempts: 720,
    questions: [
      PracticeQuestion(
        id: 'q5-1',
        text: 'Explain the bias-variance tradeoff and how you manage it in practice.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q5-2',
        text: 'How would you design an A/B test for a new Netflix recommendation feature?',
        category: QuestionCategory.Situational,
        difficulty: QuestionDifficulty.Hard,
      ),
      PracticeQuestion(
        id: 'q5-3',
        text: 'Describe a data project where your insights directly impacted a business decision.',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
      ),
    ],
  ),

  // qs-6 ─ Microsoft / DevOps
  QuestionSet(
    id: 'qs-6',
    title: 'DevOps & Cloud Engineering',
    company: 'Microsoft',
    companyInitials: 'MS',
    companyColor: _kCyan,
    difficulty: QuestionDifficulty.Easy,
    skills: ['Docker', 'Kubernetes', 'CI/CD', 'Azure'],
    totalQuestions: 10,
    estimatedTime: '~30 min',
    category: 'DevOps',
    description:
        'DevOps interview prep focusing on containerization, orchestration, and cloud platforms. Ideal for cloud/infrastructure roles.',
    rating: 4.3,
    attempts: 540,
    questions: [
      PracticeQuestion(
        id: 'q6-1',
        text: 'What is the difference between Docker containers and virtual machines?',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Easy,
      ),
      PracticeQuestion(
        id: 'q6-2',
        text: 'Describe how you would set up a CI/CD pipeline for a microservices application.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Medium,
      ),
      PracticeQuestion(
        id: 'q6-3',
        text: 'Walk me through how you handled a failed deployment in production.',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
      ),
    ],
  ),
];

// ── Practice Sessions ─────────────────────────────────────────────────────────

const practiceSessions = <PracticeSession>[
  // ps-1 — Meta qs-1 with full answers
  PracticeSession(
    id: 'ps-1',
    setId: 'qs-1',
    setTitle: 'Senior Frontend Developer Interview',
    company: 'Meta',
    companyInitials: 'M',
    companyColor: _kBlue,
    date: 'May 12, 2026',
    score: 88,
    duration: '38 min',
    skills: ['React', 'TypeScript', 'Next.js', 'Performance'],
    totalQuestions: 15,
    answers: [
      AnswerRecord(
        questionId: 'q1-1',
        questionText: 'Explain React\'s reconciliation algorithm and how the Virtual DOM works.',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Hard,
        answer:
            'React\'s reconciliation algorithm, also called the "diffing" algorithm, compares the new virtual DOM tree with the previous one to determine the minimal set of changes needed to update the real DOM. The Virtual DOM is an in-memory representation of the real DOM. When state changes, React creates a new VDOM tree, diffs it against the old one using heuristics (same-level comparison, key-based list reconciliation), and batches the minimal DOM updates. This makes UI updates fast even for complex UIs.',
        aiScore: 91,
        strengths: [
          'Clear explanation of the diffing algorithm with correct terminology',
          'Mentioned key-based reconciliation for lists — a common interview trap',
          'Structured response from concept to practical impact',
        ],
        improvements: [
          'Could mention Fiber architecture (React 16+) and its role in scheduling',
          'Missing discussion of concurrent mode and how reconciliation changed',
        ],
        suggestion:
            'Add a brief mention of React Fiber and time-slicing. Example: "React 16 introduced Fiber, rewriting reconciliation as an incremental renderer that can pause/resume work, enabling features like Suspense and concurrent rendering."',
      ),
      AnswerRecord(
        questionId: 'q1-2',
        questionText: 'How would you optimize a React application that\'s experiencing performance issues?',
        category: QuestionCategory.Technical,
        difficulty: QuestionDifficulty.Hard,
        answer:
            'First I would profile the app using React DevTools and Chrome Performance tab to identify bottlenecks. Common fixes include: wrapping expensive components with React.memo, using useMemo for computed values, useCallback for stable function references, lazy loading routes with React.lazy and Suspense, virtualization for long lists (react-virtual or react-window), and optimizing bundle size with code splitting. I would also check for unnecessary re-renders using the "why-did-you-render" library.',
        aiScore: 86,
        strengths: [
          'Methodical approach — profiling before optimizing is the right order',
          'Covered the major optimization hooks (memo, useMemo, useCallback)',
          'Mentioned virtualization, which is often overlooked',
        ],
        improvements: [
          'Didn\'t mention network-level optimizations (image optimization, CDN)',
          'Could discuss Web Vitals (LCP, FID, CLS) as measurement targets',
        ],
        suggestion:
            'Expand to include: "Beyond component-level, I measure Core Web Vitals — targeting LCP < 2.5s, FID < 100ms, and CLS < 0.1. I also audit network requests, apply image optimization (Next.js Image component), and use a CDN for static assets."',
      ),
      AnswerRecord(
        questionId: 'q1-4',
        questionText: 'Tell me about a time you had to refactor a large codebase. What was your approach?',
        category: QuestionCategory.Behavioral,
        difficulty: QuestionDifficulty.Medium,
        answer:
            'At my previous company, we had a monolithic React app with no TypeScript and minimal testing. I led a 3-month incremental migration. I started by adding TypeScript to new files only (strict mode), wrote tests for critical paths first, then gradually refactored modules starting with the most reused ones. I used feature flags so refactored code could be toggled on/off without risk. I held weekly demos to keep the team aligned and wrote detailed migration guides for each pattern change.',
        aiScore: 84,
        strengths: [
          'Concrete and specific — real timeline, real tooling',
          'STAR structure: Situation (monolith), Task (migration), Action (incremental), Result (implied)',
          'Mentioned risk mitigation (feature flags) showing engineering maturity',
        ],
        improvements: [
          'Missing the Result — what was the outcome? Test coverage %? Bug reduction?',
          'Could quantify the impact on developer velocity or deploy frequency',
        ],
        suggestion:
            'Close with measurable outcomes: "By month 3, test coverage grew from 8% to 62%, TypeScript adoption reached 80% of the codebase, and we reduced regression bugs by 40% in the next quarter. Deploy frequency also doubled as engineers felt more confident making changes."',
      ),
    ],
  ),

  // ps-2 — Stripe qs-2 (no answers)
  PracticeSession(
    id: 'ps-2',
    setId: 'qs-2',
    setTitle: 'Full Stack Engineer — Node + React',
    company: 'Stripe',
    companyInitials: 'S',
    companyColor: _kViolet,
    date: 'May 8, 2026',
    score: 72,
    duration: '32 min',
    skills: ['Node.js', 'React', 'PostgreSQL', 'REST APIs'],
    totalQuestions: 12,
    answers: [],
  ),

  // ps-3 — Google qs-3 (no answers)
  PracticeSession(
    id: 'ps-3',
    setId: 'qs-3',
    setTitle: 'Product Manager Interview Prep',
    company: 'Google',
    companyInitials: 'G',
    companyColor: _kEmerald,
    date: 'May 3, 2026',
    score: 65,
    duration: '28 min',
    skills: ['Product Strategy', 'Metrics', 'User Research', 'Roadmap'],
    totalQuestions: 10,
    answers: [],
  ),

  // ps-4 — Meta qs-1 retry (no answers)
  PracticeSession(
    id: 'ps-4',
    setId: 'qs-1',
    setTitle: 'Senior Frontend Developer Interview',
    company: 'Meta',
    companyInitials: 'M',
    companyColor: _kBlue,
    date: 'Apr 28, 2026',
    score: 79,
    duration: '41 min',
    skills: ['React', 'TypeScript', 'Next.js', 'Performance'],
    totalQuestions: 15,
    answers: [],
  ),
];

// ── Skill Radar Data ──────────────────────────────────────────────────────────

const skillRadarData = <SkillStat>[
  SkillStat(skill: 'Technical', score: 82),
  SkillStat(skill: 'Behavioral', score: 88),
  SkillStat(skill: 'Situational', score: 74),
  SkillStat(skill: 'Communication', score: 91),
  SkillStat(skill: 'Problem Solving', score: 79),
];

// ── Achievements ──────────────────────────────────────────────────────────────

const achievements = <Achievement>[
  Achievement(
    id: 'a1',
    title: 'First Practice',
    description: 'Completed your first practice session',
    icon: '🎯',
    earned: true,
    earnedDate: 'May 12, 2026',
  ),
  Achievement(
    id: 'a2',
    title: '7-Day Streak',
    description: 'Practiced for 7 consecutive days',
    icon: '🔥',
    earned: true,
    earnedDate: 'May 14, 2026',
  ),
  Achievement(
    id: 'a3',
    title: 'High Scorer',
    description: 'Scored 90+ on any session',
    icon: '⭐',
    earned: false,
  ),
  Achievement(
    id: 'a4',
    title: 'All Categories',
    description: 'Completed all question categories',
    icon: '🌟',
    earned: true,
    earnedDate: 'May 12, 2026',
  ),
  Achievement(
    id: 'a5',
    title: 'Speed Demon',
    description: 'Completed a session in under 20 minutes',
    icon: '⚡',
    earned: false,
  ),
  Achievement(
    id: 'a6',
    title: 'Consistent Learner',
    description: 'Practiced 10+ sessions total',
    icon: '📚',
    earned: true,
    earnedDate: 'May 18, 2026',
  ),
];

// ── Mock stat helpers ─────────────────────────────────────────────────────────

QuestionSet? findSetById(String id) {
  try {
    return questionSets.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

PracticeSession? findSessionForResult(String setId) {
  try {
    return practiceSessions.firstWhere(
      (s) => s.setId == setId && s.answers.isNotEmpty,
    );
  } catch (_) {
    try {
      return practiceSessions.firstWhere((s) => s.setId == setId);
    } catch (_) {
      return practiceSessions.isNotEmpty ? practiceSessions.first : null;
    }
  }
}
