from fastapi.testclient import TestClient

from app.main import create_app


class _FakeDocRef:
    def __init__(self, store: dict):
        self._store = store

    def set(self, data: dict, merge: bool = False):
        self._store['data'] = data
        self._store['merge'] = merge


class _FakeCollection:
    def __init__(self, store: dict):
        self._store = store

    def document(self, user_id: str):
        self._store['user_id'] = user_id
        return _FakeDocRef(self._store)


class _FakeDb:
    def __init__(self, store: dict):
        self._store = store

    def collection(self, name: str):
        self._store['collection'] = name
        return _FakeCollection(self._store)


def test_set_user_role_persists_and_returns_payload(monkeypatch):
    monkeypatch.setattr('app.main.init_firebase', lambda: None)

    captured: dict = {}
    monkeypatch.setattr('app.api.routes.auth.get_db', lambda: _FakeDb(captured))

    app = create_app()
    with TestClient(app) as client:
        response = client.post(
            '/api/v1/auth/role',
            json={'user_id': 'u-1', 'role': 'student'},
        )

    assert response.status_code == 200
    assert response.json() == {'user_id': 'u-1', 'role': 'student'}
    assert captured['collection'] == 'users'
    assert captured['user_id'] == 'u-1'
    assert captured['data'] == {'role': 'student'}
    assert captured['merge'] is True
