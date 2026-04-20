from fastapi.testclient import TestClient

from app.main import create_app


def test_health_check_ok(monkeypatch):
    monkeypatch.setattr('app.main.init_firebase', lambda: None)
    app = create_app()

    with TestClient(app) as client:
        response = client.get('/api/v1/health')

    assert response.status_code == 200
    assert response.json() == {'status': 'ok'}
