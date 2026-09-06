# Falcon IPTV PC

TV ve telefon için yazılan Falcon IPTV uygulamasının Windows masaüstü sürümü. Aynı Xtream Codes / M3U motoru, aynı koyu neon tema ve aynı ekranlar kullanılır.

## Özellikler

- Xtream Codes: canlı TV, film, dizi, EPG, altyazı
- M3U oynatma listesi
- Çoklu profil, favoriler, arama, kaldığı yerden devam
- Spor modu, ebeveyn PIN, QR ile profil ekleme
- Fare, klavye ve geniş pencere düzeni

## Çalıştırma

```bash
flutter pub get
flutter run -d windows
```

Çıkış paketi:

```bash
flutter build windows
```

PC güncellemeleri [iso073/falconiptvpc](https://github.com/iso073/falconiptvpc) GitHub Releases üzerinden alınır. TV downloader deposuna (`iso073/falconiptv`) bağlanılmaz.

Uygulama `releases/latest` içinden `falcontvpc.exe` (veya `falcontvpc.zip`) arar. Yeni sürüm için etiket `v1.0.1+2` gibi `pubspec.yaml` sürümüyle aynı olmalıdır:

```bash
flutter build windows --release
powershell -File tool/package_windows_release.ps1
```

Ardından `falcontvpc.exe` ve `falcontvpc.zip` bu depodaki GitHub Release’e yüklenir. `v*` etiketi push edilirse GitHub Actions aynı paketleri otomatik yayımlar.
