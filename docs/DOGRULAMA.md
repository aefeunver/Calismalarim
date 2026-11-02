# Gerçek kurulum ve test sonuçları

Tarih: **2 Kasım 2026**

## Tamamlanan kurulum

| Kontrol | Gerçek sonuç |
|---|---|
| Sanal makine | VMware üzerinde Pardus 25.2 XFCE; 6144 MB RAM, 2 vCPU |
| Debian tabanı | `/etc/debian_version`: 13.6 |
| Ağ | VMware NAT ağı üzerinden Pardus bağlantısı çalışıyor |
| Paket depoları | HTTPS depo erişimi ve imza doğrulaması başarılı |
| Yönetim erişimi | OpenSSH ve open-vm-tools kuruldu, hizmetler etkinleştirildi |
| Docker Engine | 29.9.2; Docker'ın resmi Debian deposundan kuruldu |
| Docker Compose | v5.6.1 |
| PostgreSQL | 18.6; konteyner healthy; `odev` ve `nexus` veritabanları mevcut |
| pgAdmin | 9.18; `/misc/ping` cevabı `PING`; kimlik doğrulama başarılı, `/browser/` HTTP 200 |
| pgAdmin → PostgreSQL | Bağlantı API sonucu `success: 1`, `connected: true`, `version: 180006`, veritabanı `odev` |
| pgAdmin sunucu kayıtları | `postgres:5432` üzerinde `odev` ve `nexus` önceden kayıtlı |
| Nexus ana sürüm | 3.77.2-02; HTTP durum testi başarılı |
| Nexus → PostgreSQL | `nexus` veritabanında 156 tablo ve 20 PostgreSQL JDBC bağlantısı görüldü |
| Nexus hesabı | PostgreSQL ile aynı kullanıcı/parolayı kullanan yerel laboratuvar hesabı oluşturuldu |
| Nexus EULA | Kullanıcının açık onayıyla kabul edildi |
| Artifact testi | `odev-raw` hosted deposuna `odev/merhaba.txt` yüklendi, içerik aynı şekilde geri indirildi |
| Nexus referans sürümü | 3.72.0 Java 17 Alpine ayrı volume ile çalıştırıldı; HTTP 200; hostname `kizilkoyunlu` |
| 3.72 çalışma durumu | Başarılı testten sonra kaynak tasarrufu için durduruldu; veri alanı ve konteyner korunuyor |

## Kalıcılık testi

1. PostgreSQL'de `odev_kalicilik` tablosu oluşturuldu.
2. `id=1`, `aciklama=20261102-pardus-docker-odevi` kaydı eklendi.
3. Nexus hesabı, `odev-raw` deposu ve örnek artifact hazırlandı.
4. Üç ana servis durdurulup `docker compose up -d --force-recreate` ile yeniden oluşturuldu.
5. Üç konteynerin kimlikleri değişti.
6. PostgreSQL kaydı, Nexus hesabı, repository ve artifact korundu.
7. Örnek artifact yeniden yüklenmeden GET ile okunup beklenen içerikle karşılaştırıldı.
8. PostgreSQL, pgAdmin, Nexus durum ve Nexus metadata tablo testleri tekrar geçti.

Bu, yalnızca `restart` testi değildir; konteynerlerin yeniden oluşturulması test edilmiştir.
Volume'ler silinmemiştir. pgAdmin sunucu kayıtları da yeniden oluşturma sonrasında
veri alanında bulundu ve sonradan gerçek sunucu bağlantısı kuruldu.

## Yedekleme

`scripts/backup.sh` gerçekten çalıştırıldı. Nexus ve pgAdmin durdurulup ilgili
veri alanları yedeklendi; betiğin çıkışında servisler tekrar başlatıldı.

Oluşan yerel yedek seti: `backups/20261102-103332/`

| Dosya | Yaklaşık boyut | İçerik |
|---|---:|---|
| `odev.dump` | 4 KB | Ödev veritabanının custom-format PostgreSQL yedeği |
| `nexus.dump` | 492 KB | Nexus metadata PostgreSQL yedeği |
| `nexus-data.tgz` | 57 MB | Nexus veri alanı ve blob dosyaları |
| `pgadmin-data.tgz` | 12 KB | pgAdmin kalıcı ayarları |

**Geri yükleme tatbikatı yapılmadı.** Yedek alınması ve servislerin tekrar açılması
doğrulandı; bu rapor geri yüklemenin test edildiğini iddia etmez.

## Dosyalar ve gizli bilgiler

- Kaynaklar, Compose dosyaları, kurulum/test/yedekleme betikleri ve açıklamalar GitHub'daki
  **özel** `aefeunver/pardus-docker-odevi` deposuna kaydedildi.
- `.env`, `access.txt`, `private/` ve gerçek yedekler GitHub'a gönderilmedi.
- Gerçek erişim adresleri ve parolalar yalnızca yerel giriş bilgileri dosyasındadır.
- Nexus 3.72, ödevdeki bağımsız örnek gibi H2 kullanır. PostgreSQL entegrasyonu
  doğrulanan sürüm 3.77.2'dir; 3.72 için aksi iddia edilmez.
- Bu ortam ödevin eski sürümlerini gösteren yerel bir laboratuvardır.
