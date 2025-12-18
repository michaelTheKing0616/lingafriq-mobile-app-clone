from fastapi.testclient import TestClient
from backend.main import app
client = TestClient(app)
def test_ping():
    r = client.get('/health/ping')
    assert r.status_code == 200
    assert r.json().get('status') == 'ok'
