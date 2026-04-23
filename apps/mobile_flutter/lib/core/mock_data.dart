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
      imageUrl: 'https://images.unsplash.com/photo-1515162816999-5244b23447d2?q=80&w=1000&auto=format&fit=crop',
      reactions: {'like': 10, 'sad': 5},
    ),
    ResearchPost(
      postId: 'mock_post_004',
      authorId: 'student_003',
      authorEmail: 'maria.edu@ust.edu.ph',
      title: 'AI-Powered Literacy Tutor for Rural Communities',
      abstract: 'An offline-first mobile app that uses speech recognition to help children practice reading in areas without reliable internet or teachers.',
      problemSolved: 'Low literacy rates in remote mountainous villages',
      sdgTags: ['SDG 4'],
      fundingGoal: 30000.0,
      fundingRaised: 18000.0,
      likes: 124,
      createdAt: DateTime.now().subtract(const Duration(days: 1)).toIsoformatString(),
      imageUrl: 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?q=80&w=1000&auto=format&fit=crop',
    ),
    ResearchPost(
      postId: 'mock_post_005',
      authorId: 'student_004',
      authorEmail: 'green.mind@dlsu.edu.ph',
      title: 'Mangrove Reforestation with Bio-Composite Seed Pods',
      abstract: 'Developing biodegradable pods that protect mangrove seeds from strong tides during the critical early growth phase.',
      problemSolved: 'Coastal erosion and habitat loss in Batangas',
      sdgTags: ['SDG 13', 'SDG 14'],
      fundingGoal: 100000.0,
      fundingRaised: 62000.0,
      likes: 215,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)).toIsoformatString(),
      imageUrl: 'https://images.unsplash.com/photo-1545641203-7d072a11e74a?q=80&w=1000&auto=format&fit=crop',
    ),
  ];

  static final List<Issue> issues = [
    // SDG 11: Sustainable Cities (HOT - 8 items)
    _mI('001', 'Damaged Drainage System', 'SDG 11', 14.5995, 120.9842),
    _mI('002', 'Unsafe Bridge Structure', 'SDG 11', 14.6010, 120.9850),
    _mI('003', 'Insufficient Street Lighting', 'SDG 11', 14.6020, 120.9860),
    _mI('004', 'Illegal Parking Congestion', 'SDG 11', 14.6030, 120.9870),
    _mI('005', 'Lack of PWD Ramps', 'SDG 11', 14.6040, 120.9880),
    _mI('006', 'Urban Garden Space Needed', 'SDG 11', 14.6050, 120.9890),
    _mI('007', 'Noise Pollution from Factory', 'SDG 11', 14.6060, 120.9900),
    _mI('008', 'Crumbling Pedestrian Walkway', 'SDG 11', 14.6070, 120.9910),

    // SDG 13: Climate Action (HIGH - 5 items)
    _mI('009', 'Frequent Coastal Flooding', 'SDG 13', 14.5420, 120.9780),
    _mI('010', 'Eroding River Banks', 'SDG 13', 14.5430, 120.9790),
    _mI('011', 'Extreme Heat in Market Area', 'SDG 13', 14.5440, 120.9800),
    _mI('012', 'Loss of Local Mangroves', 'SDG 13', 14.5450, 120.9810),
    _mI('013', 'Unpredictable Storm Surges', 'SDG 13', 14.5460, 120.9820),

    // SDG 6: Clean Water (MODERATE - 3 items)
    _mI('014', 'Discolored Tap Water', 'SDG 6', 14.5500, 121.0200),
    _mI('015', 'Regular Water Service Outages', 'SDG 6', 14.5510, 121.0210),
    _mI('016', 'Stagnant Water in Canals', 'SDG 6', 14.5520, 121.0220),

    // SDG 12: Responsible Consumption (MODERATE - 2 items)
    _mI('017', 'Unsegregated Public Trash', 'SDG 12', 14.5547, 121.0244),
    _mI('018', 'Excessive Plastic Packaging', 'SDG 12', 14.5550, 121.0250),

    // SDG 4: Quality Education (LOW - 1 item)
    _mI('019', 'Poor Internet in School', 'SDG 4', 14.5600, 121.0300),
  ];

  static Issue _mI(String id, String title, String sdg, double lat, double lng) {
    return Issue(
      issueId: 'mock_issue_$id',
      reporterId: 'user_mock',
      title: title,
      description: 'Automatically generated mock issue for $sdg alignment testing.',
      lat: lat,
      lng: lng,
      status: 'validated',
      createdAt: DateTime.now().toIsoformatString(),
      aiSdgTag: sdg,
    );
  }

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

  // --- USER MOCKS ---
  static final Map<String, Map<String, String>> mockUsers = {
    'student_001': {
      'name': 'River Rivera',
      'email': 'river.guard@up.edu.ph',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
      'bio': 'Civil Engineering Student @ UP Diliman. Passionate about sustainable waterways.',
    },
    'student_002': {
      'name': 'Marco Polo',
      'email': 'metro.safety@dlsu.edu.ph',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop',
      'bio': 'IoT Researcher @ DLSU. Building resilient cities through smart sensors.',
    },
    'student_003': {
      'name': 'Maria Montessori',
      'email': 'maria.edu@ust.edu.ph',
      'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
      'bio': 'Education Major @ UST. Dedicated to bridging the rural literacy gap.',
    },
    'student_004': {
      'name': 'Green Minded',
      'email': 'green.mind@dlsu.edu.ph',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop',
      'bio': 'Marine Biology Student. Reforesting our coasts one seed at a time.',
    },
    'community_001': {
      'name': 'Barangay Captain',
      'email': 'brgy.poblacion@community.local',
      'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=150&auto=format&fit=crop',
      'bio': 'Active leader in Barangay Poblacion. Driving community-led urban repair.',
    },
    'mock_user_aris': {
      'name': 'Dr. Aris',
      'avatar': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=150&auto=format&fit=crop',
    },
    'mock_user_maria': {
      'name': 'Maria Santos',
      'avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=150&auto=format&fit=crop',
    },
    'me': {
      'name': 'Me (Student)',
      'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=150&auto=format&fit=crop',
    }
  };
}

extension DateTimeIso on DateTime {
  String toIsoformatString() => toIso8601String();
}
