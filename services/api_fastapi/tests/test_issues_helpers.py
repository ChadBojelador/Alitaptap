from app.api.routes.issues import _build_title_suggestions


def test_build_title_suggestions_returns_three_unique_values():
    issue = {
        'title': 'Recurring Flooding in Riverside Homes',
        'description': 'Water rises every heavy rain and blocks school access.',
        'tags': ['SDG11'],
    }

    suggestions = _build_title_suggestions(issue, limit=3)

    assert len(suggestions) == 3
    assert len(set(suggestions)) == 3
    assert all(isinstance(item, str) and item for item in suggestions)
