import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/core/models/issue.dart';

class MockData {
  static final List<ResearchPost> researchPosts = [];

  static final List<Issue> issues = [
    _mI('b001', 'Poblacion Drainage Clog', 'SDG 11', 13.7545, 121.0545, 'Poblacion'),
    _mI('b002', 'Heritage Site Preservation', 'SDG 11', 13.7555, 121.0555, 'Poblacion'),
    _mI('b003', 'Public Market Waste Mgmt', 'SDG 12', 13.7565, 121.0565, 'Poblacion'),
    _mI('b004', 'Traffic Flow Optimization', 'SDG 9', 13.7540, 121.0530, 'Poblacion'),
    _mI('b005', 'Student Housing Congestion', 'SDG 11', 13.7750, 121.0710, 'Alangilan'),
    _mI('b006', 'Tech-Voc Center Access', 'SDG 4', 13.7760, 121.0720, 'Alangilan'),
    _mI('b007', 'Inconsistent Power Loop', 'SDG 7', 13.7745, 121.0700, 'Alangilan'),
    _mI('b008', 'Internet Dead Zones', 'SDG 9', 13.7730, 121.0690, 'Alangilan'),
    _mI('b009', 'Capitol Site Congestion', 'SDG 11', 13.7650, 121.0620, 'Kumintang Ibaba'),
    _mI('b010', 'Community Health Hub Needed', 'SDG 3', 13.7660, 121.0630, 'Kumintang Ibaba'),
    _mI('b011', 'Elderly Care Access', 'SDG 3', 13.7640, 121.0610, 'Kumintang Ibaba'),
    _mI('b012', 'Road Repair - Highway Junction', 'SDG 9', 13.7600, 121.0480, 'Calicanto'),
    _mI('b013', 'Night Security Lighting', 'SDG 11', 13.7610, 121.0490, 'Calicanto'),
    _mI('b014', 'Business District Littering', 'SDG 12', 13.7590, 121.0470, 'Calicanto'),
    _mI('b015', 'Port Area Pollution', 'SDG 14', 13.7450, 121.0400, 'Bolbok'),
    _mI('b016', 'Coastal Erosion Risk', 'SDG 13', 13.7460, 121.0410, 'Bolbok'),
    _mI('b017', 'Illegal Dumping Near Shore', 'SDG 14', 13.7440, 121.0390, 'Bolbok'),
    _mI('b018', 'Frequent Storm Surges', 'SDG 13', 13.7380, 121.0350, 'Malitam'),
    _mI('b019', 'Lack of Clean Water Supply', 'SDG 6', 13.7390, 121.0360, 'Malitam'),
    _mI('b020', 'Informal Settler Flooding', 'SDG 1', 13.7370, 121.0340, 'Malitam'),
    _mI('b021', 'Mobile Health Caravan Needs', 'SDG 3', 13.7360, 121.0330, 'Malitam'),
    _mI('b022', 'Cuta River Siltation', 'SDG 15', 13.7480, 121.0580, 'Cuta'),
    _mI('b023', 'Sustainable Farming Support', 'SDG 2', 13.8000, 121.1000, 'Balagtas'),
    _mI('b024', 'Bridge Integrity Check', 'SDG 9', 13.7800, 121.0800, 'Tingga Itaas'),
    _mI('b025', 'Gender-Neutral Restrooms', 'SDG 5', 13.7500, 121.0500, 'Batangas City'),
  ];

  static Issue _mI(String id, String title, String sdg, double lat, double lng, [String? location]) {
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
      locationName: location,
    );
  }

  static final List<Map<String, dynamic>> mockChats = [];
  static final Map<String, List<Map<String, dynamic>>> mockMessages = {};
  static final Map<String, Map<String, String>> mockUsers = {};
}

extension DateTimeIso on DateTime {
  String toIsoformatString() => toIso8601String();
}
