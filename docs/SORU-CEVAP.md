# Ödevi anlatmak için teknik notlar

## Linux dağıtımı nedir?
Linux çekirdeği, sistem araçları, paket yöneticisi ve uygulamaları bir araya getiren
işletim sistemi dağıtımıdır. Debian, Ubuntu, Pardus, Fedora, Linux Mint, openSUSE
ve Arch Linux örneklerdir. Pardus Debian tabanlıdır; paket yönetiminde APT kullanır.

## Sanal makine ve konteyner arasındaki fark nedir?
VMware sanal donanım üzerinde ayrı bir işletim sistemi çalıştırır. Docker
konteynerleri çalıştıkları Linux çekirdeğini paylaşır. Bu ödevde Pardus sanal
makinedir; PostgreSQL, pgAdmin ve Nexus onun içindeki konteynerlerdir.

## Image, container, volume ve network nedir?
- Image: Uygulamanın sürümlenmiş dağıtım şablonu.
- Container: Image'dan oluşturulan çalışan uygulama örneği.
- Volume: Konteynerin yaşam döngüsünden bağımsız kalıcı veri alanı.
- Network: Servislerin adları üzerinden birbirlerine ulaşmasını sağlayan Docker ağı.

## docker pull ve docker run farkı nedir?
`pull` imajı indirir. `run` imajdan konteyner oluşturur ve çalıştırır. Compose aynı
işlemleri dosyada tanımlanan birden fazla servis için yönetir.

## PostgreSQL ve pgAdmin farkı nedir?
PostgreSQL veritabanı sunucusudur. pgAdmin yönetim arayüzüdür. pgAdmin arayüzüne
girmek ve PostgreSQL sunucusuna bağlanmak iki ayrı kimlik doğrulama işlemidir.

## Port eşlemesi nasıl okunur?
`5050:80`, sunucunun 5050 portuna gelen bağlantıyı konteynerin 80 portuna yönlendirir.
`127.0.0.1:5050:80` sunucu tarafında erişimi yerel adresle sınırlar. Konteynerler
birbirlerine host portundan değil Docker ağı üzerindeki servis portundan ulaşır.

## Nexus'un depo türleri nelerdir?
- Hosted: Kendi paketlerini / artifact'larını saklar.
- Proxy: Uzak depodan indirilen paketleri önbelleğe alır.
- Group: Birden fazla depoyu tek erişim adresi altında birleştirir.

## Nexus PostgreSQL'e nasıl bağlanır?
JDBC adresi, kullanıcı adı ve parola ile. Bu projede adres
`jdbc:postgresql://postgres:5432/nexus` olur. Aynı kullanıcı/parolayı tanımlamak
tek başına bağlantı değildir; uygulamanın bu JDBC bağlantısını kullanması gerekir.
Bağlantı, Nexus tabloları ve PostgreSQL'deki canlı oturumlar ile doğrulanmalıdır.

## Java bellek parametreleri ne demek?
`-Xms1024m` heap başlangıç boyutu, `-Xmx1024m` heap üst sınırı,
`-XX:MaxDirectMemorySize=1024m` doğrudan bellek sınırıdır. Bunlar toplam konteyner
belleğinin 1 GB ile sınırlı olduğu anlamına gelmez.

## Kalıcılık nasıl kanıtlanır?
Test tablosuna kayıt eklenir ve Nexus'a örnek artifact yüklenir. Konteynerler aynı
volume'lerle yeniden oluşturulur. Kayıt ve artifact hâlâ varsa bu senaryo için
kalıcılık doğrulanmıştır. Yalnızca `restart` yapmak daha sınırlı bir testtir.

## Neyi gerçekten tamamladım?
Bu sorunun cevabı `DOGRULAMA.md` dosyasındaki gerçek test sonuçlarıdır. Planlanan,
yalnızca dosyası hazırlanmış ve çalıştırılarak doğrulanmış işleri birbirine karıştırmayın.
