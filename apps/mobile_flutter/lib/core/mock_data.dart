import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/core/models/issue.dart';

/// ALITAPTAP MOCK DATA STORE
/// This file contains hardcoded mockup data to ensure the app looks "alive"
/// even without a backend connection or if Firestore is empty.
class MockData {
  static final List<ResearchPost> researchPosts = [
    ResearchPost(
      postId: 'mock_post_001',
      authorId: 'student_001',
      authorEmail: 'river.guard@up.edu.ph',
      title: 'River Plastic Recovery Through Community Sorting Stations',
      abstract: 'This project evaluates low-cost sorting stations near waterways to reduce plastic runoff. We implement physical barriers and community-led sorting to prevent trash from reaching the ocean.',
      problemSolved: 'Plastic waste in Pasig River waterways',
      sdgTags: ['SDG 6', 'SDG 11', 'SDG 12', 'SDG 14'],
      fundingGoal: 50000.0,
      fundingRaised: 12500.0,
      likes: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIsoformatString(),
      imageUrl: 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?q=80&w=1000&auto=format&fit=crop', // River trash cleanup
      likedBy: ['user1', 'user2'],
      reactions: {'like': 30, 'love': 12},
    ),
    ResearchPost(
      postId: 'mock_post_002',
      authorId: 'student_002',
      authorEmail: 'metro.safety@dlsu.edu.ph',
      title: 'Barangay Flood Early Warning with Low-Cost IoT Sensors',
      abstract: 'An affordable early-warning concept designed to alert residents before floodwaters become dangerous. USes ultrasonic sensors and SMS gateways.',
      problemSolved: 'Recurring community flooding in low-lying areas',
      sdgTags: ['SDG 9', 'SDG 11', 'SDG 13'],
      fundingGoal: 75000.0,
      fundingRaised: 45000.0,
      likes: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 5)).toIsoformatString(),
      imageUrl: 'https://images.unsplash.com/photo-1547619292-8816ee7cdd50?q=80&w=1000&auto=format&fit=crop', // Flood/Water monitoring
      likedBy: ['user3', 'user4'],
      reactions: {'love': 50, 'wow': 39},
    ),
    ResearchPost(
      postId: 'mock_post_003',
      authorId: 'community_001',
      authorEmail: 'brgy.poblacion@community.local',
      title: 'Urban Pothole Mapping & Predictive Repair Scheduling',
      abstract: 'Using crowdsourced mobile gyro data to map road damage and predict which potholes will become dangerous safety hazards within weeks.',
      problemSolved: 'Road Damage and Potholes',
      sdgTags: ['SDG 9', 'SDG 11'],
      fundingGoal: 20000.0,
      fundingRaised: 2000.0,
      likes: 15,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)).toIsoformatString(),
      imageUrl: 'https://images.unsplash.com/photo-1515162816999-5244b23447d2?q=80&w=1000&auto=format&fit=crop', // Broken road
      reactions: {'like': 10, 'sad': 5},
    ),
  ];

  static final List<Issue> issues = [
    Issue(
      issueId: 'mock_issue_001',
      reporterId: 'community_user_001',
      title: 'Road Damage and Potholes',
      description: "Our local roads are getting harder to navigate by the day. From deep potholes to crumbling asphalt, these conditions aren't just an inconvenience—they're a safety hazard.",
      lat: 14.5995,
      lng: 120.9842,
      status: 'validated',
      createdAt: DateTime.now().subtract(const Duration(days: 10)).toIsoformatString(),
    ),
    Issue(
      issueId: 'mock_issue_002',
      reporterId: 'community_user_002',
      title: 'Illegal Waste Dumping Hotspot',
      description: "Construction debris and household waste are being dumped at this vacant lot every weekend. It's attracting pests and causing foul odors for the entire block.",
      lat: 14.5547,
      lng: 121.0244,
      status: 'validated',
      createdAt: DateTime.now().subtract(const Duration(days: 3)).toIsoformatString(),
    ),
  ];

  // --- CHAT MOCKS ---
  
  static final List<Map<String, dynamic>> mockChats = [
    {
      'other_uid': 'mock_user_aris',
      'other_email': 'dr.aris@up.edu.ph',
      'last_message': 'I saw your research on river plastics. Can we collaborate?',
      'last_message_at': DateTime.now().subtract(const Duration(hours: 2)),
      'unreadCount': 1,
    },
    {
      'other_uid': 'mock_user_maria',
      'other_email': 'maria.santos@gmail.com',
      'last_message': 'Thank you for documenting the flood risk in our area.',
      'last_message_at': DateTime.now().subtract(const Duration(days: 1)),
      'unreadCount': 0,
    },
    {
      'other_uid': 'mock_user_ben',
      'other_email': 'engr.ben@dost.gov.ph',
      'last_message': 'The sensor prototype looks promising. Let\'s discuss funding.',
      'last_message_at': DateTime.now().subtract(const Duration(days: 3)),
      'unreadCount': 0,
    },
  ];

  static final Map<String, List<Map<String, dynamic>>> mockMessages = {
    'mock_user_aris': [
      {'sender_uid': 'mock_user_aris', 'text': 'Hello! I am Dr. Aris from UP.', 'created_at': DateTime.now().subtract(const Duration(hours: 3))},
      {'sender_uid': 'me', 'text': 'Hi Dr. Aris! Nice to meet you.', 'created_at': DateTime.now().subtract(const Duration(hours: 2, minutes: 30))},
      {'sender_uid': 'mock_user_aris', 'text': 'I saw your research on river plastics. Can we collaborate?', 'created_at': DateTime.now().subtract(const Duration(hours: 2))},
    ],
    'mock_user_maria': [
      {'sender_uid': 'mock_user_maria', 'text': 'Hi, I live in Brgy. 123.', 'created_at': DateTime.now().subtract(const Duration(days: 2))},
      {'sender_uid': 'me', 'text': 'How can I help you?', 'created_at': DateTime.now().subtract(const Duration(days: 1, hours: 5))},
      {'sender_uid': 'mock_user_maria', 'text': 'Thank you for documenting the flood risk in our area.', 'created_at': DateTime.now().subtract(const Duration(days: 1))},
    ],
  };
}

extension DateTimeIso on DateTime {
  String toIsoformatString() => toIso8601String();
}
