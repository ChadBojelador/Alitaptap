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

  static final List<Issue> issues = [
    _mI('b001', 'Poblacion Drainage Clog', 'SDG 11', 13.7545, 121.0545,
        'Poblacion'),
    _mI('b002', 'Heritage Site Preservation', 'SDG 11', 13.7555, 121.0555,
        'Poblacion'),
    _mI('b003', 'Public Market Waste Mgmt', 'SDG 12', 13.7565, 121.0565,
        'Poblacion'),
    _mI('b004', 'Traffic Flow Optimization', 'SDG 9', 13.7540, 121.0530,
        'Poblacion'),
    _mI('b005', 'Student Housing Congestion', 'SDG 11', 13.7750, 121.0710,
        'Alangilan'),
    _mI('b006', 'Tech-Voc Center Access', 'SDG 4', 13.7760, 121.0720,
        'Alangilan'),
    _mI('b007', 'Inconsistent Power Loop', 'SDG 7', 13.7745, 121.0700,
        'Alangilan'),
    _mI('b008', 'Internet Dead Zones', 'SDG 9', 13.7730, 121.0690, 'Alangilan'),
    _mI('b009', 'Capitol Site Congestion', 'SDG 11', 13.7650, 121.0620,
        'Kumintang Ibaba'),
    _mI('b010', 'Community Health Hub Needed', 'SDG 3', 13.7660, 121.0630,
        'Kumintang Ibaba'),
    _mI('b011', 'Elderly Care Access', 'SDG 3', 13.7640, 121.0610,
        'Kumintang Ibaba'),
    _mI('b012', 'Road Repair - Highway Junction', 'SDG 9', 13.7600, 121.0480,
        'Calicanto'),
    _mI('b013', 'Night Security Lighting', 'SDG 11', 13.7610, 121.0490,
        'Calicanto'),
    _mI('b014', 'Business District Littering', 'SDG 12', 13.7590, 121.0470,
        'Calicanto'),
    _mI('b015', 'Port Area Pollution', 'SDG 14', 13.7450, 121.0400, 'Bolbok'),
    _mI('b016', 'Coastal Erosion Risk', 'SDG 13', 13.7460, 121.0410, 'Bolbok'),
    _mI('b017', 'Illegal Dumping Near Shore', 'SDG 14', 13.7440, 121.0390,
        'Bolbok'),
    _mI('b018', 'Frequent Storm Surges', 'SDG 13', 13.7380, 121.0350,
        'Malitam'),
    _mI('b019', 'Lack of Clean Water Supply', 'SDG 6', 13.7390, 121.0360,
        'Malitam'),
    _mI('b020', 'Informal Settler Flooding', 'SDG 1', 13.7370, 121.0340,
        'Malitam'),
    _mI('b021', 'Mobile Health Caravan Needs', 'SDG 3', 13.7360, 121.0330,
        'Malitam'),
    _mI('b022', 'Cuta River Siltation', 'SDG 15', 13.7480, 121.0580, 'Cuta'),
    _mI('b023', 'Sustainable Farming Support', 'SDG 2', 13.8000, 121.1000,
        'Balagtas'),
    _mI('b024', 'Bridge Integrity Check', 'SDG 9', 13.7800, 121.0800,
        'Tingga Itaas'),
    _mI('b025', 'Gender-Neutral Restrooms', 'SDG 5', 13.7500, 121.0500,
        'Batangas City'),
  ];

  static Issue _mI(String id, String title, String sdg, double lat, double lng,
      [String? location]) {
    return Issue(
      issueId: 'mock_issue_$id',
      reporterId: 'user_mock',
      title: title,
      description:
          'Automatically generated mock issue for $sdg alignment testing.',
      lat: lat,
      lng: lng,
      status: 'validated',
      createdAt: DateTime.now().toIsoformatString(),
      aiSdgTag: sdg,
      locationName: location,
    );
  }

  static final List<CommunityProblemPost> communityProblems = [
    CommunityProblemPost(
      postId: 'community_001',
      reporterName: 'Juan Dela Cruz',
      title: 'Punong Basurahan sa Barangay',
      description:
          'Grabe sa mga barangay streets talaga… minsan 2–3 times a week lang dumadaan yung garbage collection. Ang ending, overflowing na agad yung mga basurahan 😩 Puno agad ng plastic bottles, sachet, at kung ano-anong basura.\n\nNakaka-frustrate kasi kahit maayos ka magtapon, wala nang space yung bins. So yung iba, napipilitan magtapon sa tabi o sa kalsada 😤\n\nKaya imbes na controlled yung basura, nagiging kalat-kalat pa rin sa paligid. Ang hirap din linisin lalo na pag umulan, kasi nadadala pa sa ibang lugar yung plastic waste 🥲',
      createdAt: DateTime.now().toIsoformatString(),
      likes: 0,
      likedBy: const [],
      shares: 0,
      imageUrls: const [
        'assets/mock_pictures/problem_post_picture/Punong Basurahan sa Barangay.jpg',
      ],
    ),
    CommunityProblemPost(
      postId: 'community_002',
      reporterName: 'Maria Santos',
      title: 'Tubig na Laging Pinuputol',
      description:
          'Grabe sa barangay namin… halos linggo-linggo na lang may water interruption 😩 Minsan ilang oras, minsan buong araw pa bago bumalik. Ang ending, hirap magluto, maligo, at maglinis sa bahay.\n\nNakaka-frustrate kasi kahit nag-iipon ka ng tubig, minsan kulang pa rin lalo na pag biglaan yung putol. Yung iba napipilitang bumili ng mahal na purified water o makiigib sa kapitbahay 😤\n\nKaya imbes na maayos yung daily routine, naaantala lahat ng gawain. Ang hirap din lalo na sa mga may bata o senior sa bahay 🥲',
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIsoformatString(),
      likes: 0,
      likedBy: const [],
      shares: 0,
      imageUrls: const [
        'assets/mock_pictures/problem_post_picture/Tubig na Laging Pinuputol.jpg',
      ],
    ),
    CommunityProblemPost(
      postId: 'community_003',
      reporterName: 'Carlo Reyes',
      title: 'Dilim sa Kalsada Tuwing Gabi',
      description:
          'Grabe sa mga eskinita dito… andaming streetlights na sira o hindi umiilaw 😩 Pagdating ng gabi, sobrang dilim at nakakatakot dumaan lalo na pag mag-isa ka.\n\nNakaka-frustrate kasi basic safety na nga lang, hindi pa maayos. Yung iba napipilitang umiwas sa daan o maglakad nang malayo para lang sa may ilaw 😤\n\nKaya imbes na safe ang komunidad, nagiging risky pa para sa mga estudyante, workers, at residents. Ang hirap din pag may emergency sa gabi 🥲',
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 10))
          .toIsoformatString(),
      likes: 0,
      likedBy: const [],
      shares: 0,
      imageUrls: const [
        'assets/mock_pictures/problem_post_picture/Dilim sa Kalsada Tuwing Gabi.jpg',
      ],
    ),
    CommunityProblemPost(
      postId: 'community_004',
      reporterName: 'Ana Villanueva',
      title: 'Traffic at Walang Maayos na Sakayan',
      description:
          'Grabe sa main road dito… araw-araw na lang sobrang traffic at hirap sumakay 😩 Minsan inaabot ng isang oras bago makahanap ng masasakyang jeep o bus.\n\nNakaka-frustrate kasi nasasayang oras at pagod ng mga tao papasok sa trabaho o school. Yung iba nale-late na lang palagi kahit maaga umalis 😤\n\nKaya imbes na productive ang araw, nauubos na agad energy sa biyahe pa lang. Ang hirap din para sa commuters lalo na pag umuulan 🥲',
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIsoformatString(),
      likes: 0,
      likedBy: const [],
      shares: 0,
      imageUrls: const [
        'assets/mock_pictures/problem_post_picture/Traffic at Walang Maayos na Sakayan.jpg',
      ],
    ),
    CommunityProblemPost(
      postId: 'community_005',
      reporterName: 'Mark Lopez',
      title: 'Baha Kada Malakas na Ulan',
      description:
          'Grabe sa area namin… konting malakas na ulan lang, baha agad sa kalsada 😩 Yung mga kanal barado na rin kaya hindi makadaloy nang maayos yung tubig.\n\nNakaka-frustrate kasi hindi na makadaan ang tao at sasakyan. Yung iba napipilitang lumusong sa maruming baha para lang makauwi o makapasok 😤\n\nKaya imbes na normal lang ang rainy season, nagiging perwisyo at delikado pa sa health at safety ng residents. Ang hirap din linisin pagkatapos humupa ng baha 🥲',
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 20))
          .toIsoformatString(),
      likes: 0,
      likedBy: const [],
      shares: 0,
      imageUrls: const [
        'assets/mock_pictures/problem_post_picture/Baha Kada Malakas na Ulan.jpg',
      ],
    ),
  ];

  static final List<StoryPost> storyPosts = [
    const StoryPost(
      storyId: 'story_001',
      bubbleLabel: 'Soap',
      title: 'Soap Project Story',
      description:
          'A hygiene-focused student project that explores low-cost soap solutions for households and community sanitation.',
      sdgLabel: 'SDG 3',
      sdgName: 'Good Health and Well-being',
      imagePath: 'assets/mock_pictures/story_post/soap project story.jpg',
    ),
    const StoryPost(
      storyId: 'story_002',
      bubbleLabel: 'Shredder',
      title: 'Paper Shredder Story',
      description:
          'A paper recycling and shredding initiative that helps reduce paper waste and encourages responsible material reuse.',
      sdgLabel: 'SDG 12',
      sdgName: 'Responsible Consumption and Production',
      imagePath: 'assets/mock_pictures/story_post/paper shredder story.jpg',
    ),
    const StoryPost(
      storyId: 'story_003',
      bubbleLabel: 'Monitoring',
      title: 'Monitoring System Story',
      description:
          'A community monitoring setup designed to improve local issue tracking and support faster barangay response workflows.',
      sdgLabel: 'SDG 11',
      sdgName: 'Sustainable Cities and Communities',
      imagePath: 'assets/mock_pictures/story_post/monitoring system story.jpg',
    ),
    const StoryPost(
      storyId: 'story_004',
      bubbleLabel: 'Earthquake',
      title: 'Earthquake System Story',
      description:
          'An early-warning concept for earthquake preparedness that supports safer schools and community evacuation readiness.',
      sdgLabel: 'SDG 11',
      sdgName: 'Sustainable Cities and Communities',
      imagePath:
          'assets/mock_pictures/story_post/earfth quake system story.jpg',
    ),
  ];

  static final List<Map<String, dynamic>> mockChats = [
    {
      'chat_id': 'chat_001',
      'other_uid': 'community_juan',
      'last_message':
          'Salamat! Kailan pwede i-pilot test ang SmartBin sa amin?',
      'last_message_at': DateTime.now()
          .subtract(const Duration(minutes: 2))
          .toIsoformatString(),
      'unread_count': 2,
      'is_online': true,
    },
    {
      'chat_id': 'chat_002',
      'other_uid': 'community_maria',
      'last_message': 'Mukhang helpful ang AquaAlert para sa barangay namin.',
      'last_message_at': DateTime.now()
          .subtract(const Duration(minutes: 8))
          .toIsoformatString(),
      'unread_count': 0,
      'is_online': false,
    },
    {
      'chat_id': 'chat_003',
      'other_uid': 'community_carlo',
      'last_message': 'Pwede bang ma-link sa report system ng streetlights?',
      'last_message_at': DateTime.now()
          .subtract(const Duration(minutes: 26))
          .toIsoformatString(),
      'unread_count': 1,
      'is_online': true,
    },
    {
      'chat_id': 'chat_004',
      'other_uid': 'community_ana',
      'last_message': 'May demo ba ang CommuteEase para sa students?',
      'last_message_at': DateTime.now()
          .subtract(const Duration(hours: 1, minutes: 12))
          .toIsoformatString(),
      'unread_count': 0,
      'is_online': false,
    },
    {
      'chat_id': 'chat_005',
      'other_uid': 'community_mark',
      'last_message':
          'Nakatulong yung FloodGuard idea sa hazard planning meeting.',
      'last_message_at': DateTime.now()
          .subtract(const Duration(hours: 3, minutes: 4))
          .toIsoformatString(),
      'unread_count': 0,
      'is_online': false,
    },
  ];

  static final Map<String, List<Map<String, dynamic>>> mockMessages = {
    'chat_001': [
      {
        'sender_uid': 'community_juan',
        'text': 'Salamat! Kailan pwede i-pilot test ang SmartBin sa amin?',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 2))
            .toIsoformatString(),
      },
    ],
    'chat_002': [
      {
        'sender_uid': 'community_maria',
        'text': 'Mukhang helpful ang AquaAlert para sa barangay namin.',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 8))
            .toIsoformatString(),
      },
    ],
    'chat_003': [
      {
        'sender_uid': 'community_carlo',
        'text': 'Pwede bang ma-link sa report system ng streetlights?',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 26))
            .toIsoformatString(),
      },
    ],
    'chat_004': [
      {
        'sender_uid': 'community_ana',
        'text': 'May demo ba ang CommuteEase para sa students?',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 1, minutes: 12))
            .toIsoformatString(),
      },
    ],
    'chat_005': [
      {
        'sender_uid': 'community_mark',
        'text': 'Nakatulong yung FloodGuard idea sa hazard planning meeting.',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 3, minutes: 4))
            .toIsoformatString(),
      },
    ],
  };
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
