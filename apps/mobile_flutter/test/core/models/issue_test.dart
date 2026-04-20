import 'package:alitaptap_mobile/core/models/issue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Issue.fromJson parses coordinates and tags', () {
    final issue = Issue.fromJson({
      'issue_id': 'issue-1',
      'reporter_id': 'user-1',
      'title': 'Flooded Street',
      'description': 'Water level reaches knee height',
      'lat': 14.5995,
      'lng': 120.9842,
      'status': 'validated',
      'tags': ['flood', 'sdg11'],
      'created_at': '2026-04-21T10:00:00Z',
    });

    expect(issue.issueId, 'issue-1');
    expect(issue.title, 'Flooded Street');
    expect(issue.lat, 14.5995);
    expect(issue.lng, 120.9842);
    expect(issue.tags, ['flood', 'sdg11']);
    expect(issue.status, 'validated');
  });
}
