# /tests/test_main.py

# 'client' parametresi, 'conftest.py' dosyasındaki 'client' fixture'ından
# otomatik olarak gelecektir.
def test_read_root(client):
    # Ana sayfaya (/) bir GET isteği yap
    response = client.get("/")
    
    # 1. Kontrol: HTTP durum kodunun 200 (OK) olduğunu doğrula
    assert response.status_code == 200
    
    # 2. Kontrol: Dönen JSON mesajının beklediğimiz gibi olduğunu doğrula
    assert response.json() == {"message": "Welcome to TasarimciBulutu API"}