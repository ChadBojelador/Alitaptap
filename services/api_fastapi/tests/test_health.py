from fastapi.testclient import TestClient

from app.main import create_app


def test_health_check_ok(monkeypatch):
    monkeypatch.setattr('app.main.init_firebase', lambda: None)
    app = create_app()

    with TestClient(app) as client:
        response = client.get('/api/v1/health')

    assert response.status_code == 200
    assert response.json() == {'status': 'ok'}


def test_cors_allows_localhost_origins_with_ports(monkeypatch):
    monkeypatch.setattr('app.main.init_firebase', lambda: None)
    app = create_app()

    with TestClient(app) as client:
        for origin in ('http://localhost:5173', 'http://127.0.0.1:61452'):
            response = client.options(
                '/api/v1/health',
                headers={
                    'Origin': origin,
                    'Access-Control-Request-Method': 'GET',
                },
            )
            assert response.status_code == 200
            assert response.headers.get('access-control-allow-origin') == origin
