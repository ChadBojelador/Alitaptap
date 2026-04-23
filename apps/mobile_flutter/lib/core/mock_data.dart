import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/core/models/issue.dart';
import 'package:alitaptap_mobile/core/models/community_problem_post.dart';

class MockData {
  static final List<ResearchPost> researchPosts = [];

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
      // Replace these with actual image URLs or asset paths later.
      imageUrls: const [
        'placeholder://juan-basura-1',
        'placeholder://juan-basura-2',
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
        'placeholder://maria-tubig-1',
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
        'placeholder://carlo-ilaw-1',
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
        'placeholder://ana-traffic-1',
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
        'placeholder://mark-baha-1',
      ],
    ),
  ];

  static final List<Map<String, dynamic>> mockChats = [];
  static final Map<String, List<Map<String, dynamic>>> mockMessages = {};
  static final Map<String, Map<String, String>> mockUsers = {};
}

extension DateTimeIso on DateTime {
  String toIsoformatString() => toIso8601String();
}
