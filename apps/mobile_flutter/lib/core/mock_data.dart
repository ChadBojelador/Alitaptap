import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/core/models/issue.dart';
import 'package:alitaptap_mobile/core/models/community_problem_post.dart';
import 'package:alitaptap_mobile/core/models/story_post.dart';

class MockData {
  static final List<ResearchPost> researchPosts = [
    ResearchPost(
      postId: 'research_001',
      authorId: 'student_smartbin',
      authorEmail: 'SmartBin Team',
      title:
          'SmartBin Connect: Barangay Waste Monitoring and Collection Optimization System',
      abstract:
          'SmartBin Connect is a smart waste management system that uses sensor-enabled garbage bins to monitor fill levels in real time. When bins are nearly full, automatic alerts are sent to barangay waste collectors for immediate pickup. The system also maps high-waste areas, schedules efficient collection routes, and promotes segregation reminders to residents. This helps prevent overflowing bins, roadside littering, and plastic waste spreading during rainy days.',
      problemSolved:
          'Overflowing bins, delayed collection, and roadside littering in barangays.',
      sdgTags: const ['SDG 11', 'SDG 12', 'SDG 13', 'SDG 3'],
      fundingGoal: 150000,
      fundingRaised: 42000,
      likes: 24,
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 1))
          .toIsoformatString(),
      imageUrls: const [
        'assets/mock_pictures/research_post_picture/smart-bin-01.png',
        'assets/mock_pictures/research_post_picture/smart-bin-02.png',
      ],
      shares: 8,
      reactions: const {'like': 16, 'love': 5, 'wow': 3},
    ),
    ResearchPost(
      postId: 'research_002',
      authorId: 'student_aquaalert',
      authorEmail: 'AquaAlert Team',
      title:
          'AquaAlert: Smart Water Interruption Notification and Storage Monitoring System',
      abstract:
          'AquaAlert is a community-based system that provides real-time announcements on scheduled and emergency water interruptions. It also helps households track stored water levels and gives conservation tips during shortages. The platform aims to reduce inconvenience and improve access to clean water management in barangays.',
      problemSolved:
          'Frequent water interruptions and poor household water readiness.',
      sdgTags: const ['SDG 6', 'SDG 11'],
      fundingGoal: 120000,
      fundingRaised: 28000,
      likes: 17,
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 2))
          .toIsoformatString(),
      imageUrls: const [
        'assets/mock_pictures/research_post_picture/AquaAlert.jpg',
      ],
      shares: 5,
      reactions: const {'like': 11, 'love': 3, 'wow': 3},
    ),
    ResearchPost(
      postId: 'research_003',
      authorId: 'student_brightpath',
      authorEmail: 'BrightPath Team',
      title: 'BrightPath: Solar-Powered Smart Streetlight Monitoring System',
      abstract:
          'BrightPath is a smart streetlight solution that uses solar energy and sensor-based monitoring to detect broken or non-functioning streetlights. Reports are automatically sent to barangay officials for faster repairs, improving road safety and visibility at night.',
      problemSolved: 'Broken streetlights and unsafe dark streets at night.',
      sdgTags: const ['SDG 7', 'SDG 11', 'SDG 16'],
      fundingGoal: 180000,
      fundingRaised: 36000,
      likes: 15,
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 3))
          .toIsoformatString(),
      imageUrls: const [
        'assets/mock_pictures/research_post_picture/BrightPath.jpg',
      ],
      shares: 4,
      reactions: const {'like': 10, 'love': 2, 'wow': 3},
    ),
    ResearchPost(
      postId: 'research_004',
      authorId: 'student_commuteease',
      authorEmail: 'CommuteEase Team',
      title: 'CommuteEase: Smart Queueing and Transport Availability App',
      abstract:
          'CommuteEase is a mobile platform that helps commuters view transport availability, waiting times, and optimized pickup areas in real time. It supports smoother commuting experiences, reduces traffic congestion, and improves daily productivity for workers and students.',
      problemSolved:
          'Long wait times, traffic bottlenecks, and unreliable commuting.',
      sdgTags: const ['SDG 9', 'SDG 11', 'SDG 8'],
      fundingGoal: 130000,
      fundingRaised: 22000,
      likes: 13,
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 4))
          .toIsoformatString(),
      imageUrls: const [
        'assets/mock_pictures/research_post_picture/CommuteEase.jpg',
      ],
      shares: 3,
      reactions: const {'like': 9, 'love': 1, 'wow': 3},
    ),
    ResearchPost(
      postId: 'research_005',
      authorId: 'student_floodguard',
      authorEmail: 'FloodGuard Team',
      title: 'FloodGuard: Community Flood Detection and Drainage Alert System',
      abstract:
          'FloodGuard uses water-level sensors and weather monitoring to provide early flood warnings in flood-prone barangays. It also tracks clogged drainage areas through community reports, helping local officials respond faster and reduce flood damage.',
      problemSolved:
          'Recurring floods, drainage clogging, and delayed response.',
      sdgTags: const ['SDG 13', 'SDG 11', 'SDG 3'],
      fundingGoal: 170000,
      fundingRaised: 31000,
      likes: 20,
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 6))
          .toIsoformatString(),
      imageUrls: const [
        'assets/mock_pictures/research_post_picture/FloodGuard.jpg',
      ],
      shares: 6,
      reactions: const {'like': 14, 'love': 3, 'wow': 3},
    ),
  ];

  /// No mock issues — map shows only real user-submitted & validated data.
  static final List<Issue> issues = [];

  static final List<CommunityProblemPost> communityProblems = [];

  static final List<StoryPost> storyPosts = [];

  static final List<Map<String, dynamic>> mockChats = [];

  static final Map<String, List<Map<String, dynamic>>> mockMessages = {};
  static final Map<String, Map<String, String>> mockUsers = {
    'student_smartbin': {
      'name': 'SmartBin Team',
      'email': 'SmartBin Team',
      'avatar': 'assets/mock_pictures/research_post_picture/smart-bin-01.png',
    },
    'student_aquaalert': {
      'name': 'AquaAlert Team',
      'email': 'AquaAlert Team',
      'avatar': 'assets/mock_pictures/research_post_picture/AquaAlert.jpg',
    },
    'student_brightpath': {
      'name': 'BrightPath Team',
      'email': 'BrightPath Team',
      'avatar': 'assets/mock_pictures/research_post_picture/BrightPath.jpg',
    },
    'student_commuteease': {
      'name': 'CommuteEase Team',
      'email': 'CommuteEase Team',
      'avatar': 'assets/mock_pictures/research_post_picture/CommuteEase.jpg',
    },
    'student_floodguard': {
      'name': 'FloodGuard Team',
      'email': 'FloodGuard Team',
      'avatar': 'assets/mock_pictures/research_post_picture/FloodGuard.jpg',
    },
    'community_juan': {
      'name': 'Juan Dela Cruz',
      'email': 'Juan Dela Cruz',
      'avatar':
          'assets/mock_pictures/problem_post_picture/Punong Basurahan sa Barangay.jpg',
    },
    'community_maria': {
      'name': 'Maria Santos',
      'email': 'Maria Santos',
      'avatar':
          'assets/mock_pictures/problem_post_picture/Tubig na Laging Pinuputol.jpg',
    },
    'community_carlo': {
      'name': 'Carlo Reyes',
      'email': 'Carlo Reyes',
      'avatar':
          'assets/mock_pictures/problem_post_picture/Dilim sa Kalsada Tuwing Gabi.jpg',
    },
    'community_ana': {
      'name': 'Ana Villanueva',
      'email': 'Ana Villanueva',
      'avatar':
          'assets/mock_pictures/problem_post_picture/Traffic at Walang Maayos na Sakayan.jpg',
    },
    'community_mark': {
      'name': 'Mark Lopez',
      'email': 'Mark Lopez',
      'avatar':
          'assets/mock_pictures/problem_post_picture/Baha Kada Malakas na Ulan.jpg',
    },
  };
}

extension DateTimeIso on DateTime {
  String toIsoformatString() => toIso8601String();
}
