# MDW Toolkit

> WordPress eklentilerini geliştirmek, doğrulamak, test etmek ve yayınlamak için profesyonel PowerShell CLI aracı.

<p align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![PowerShell 7](https://img.shields.io/badge/PowerShell-7%2B-2C89A0?style=for-the-badge&logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/Lisans-MIT-green?style=for-the-badge)

</p>

---

MDW Toolkit, profesyonel WordPress eklenti geliştirme süreçleri için tasarlanmış, üretim kalitesinde bir komut satırı aracıdır.

Standart bir çalışma alanı oluşturur, doğrulama, test, build, ZIP ve release süreçlerini tek bir CLI deneyimi altında birleştirir.

---

## Neden MDW?

- Standart WordPress geliştirme çalışma alanı
- Otomatik Build, ZIP ve Release Pipeline
- Yerleşik eklenti doğrulama sistemi
- WordPress Plugin Check entegrasyonu
- Git iş akışı desteği
- LocalWP entegrasyonu
- Production kalitesinde CLI mimarisi
- PowerShell 5.1 ve PowerShell 7 uyumluluğu

---

## Ekran Görüntüleri

Aşağıdaki ekran görüntüleri doğrudan MDW Toolkit çalıştırılarak alınmıştır.

*(Ekran görüntüleri bir sonraki bölümde eklenecektir.)*

---

## Demo

Gerçek CLI çalışma akışını gösteren demo video.

*(Demo videosu bir sonraki bölümde eklenecektir.)*

---

## Hızlı Başlangıç

### 1. Depoyu klonlayın

```powershell
git clone https://github.com/muratzden/mdw-toolkit.git
cd mdw-toolkit
```

### 2. MDW Toolkit'i kurun

```powershell
.\install.ps1
```

### 3. Kurulumu doğrulayın

```powershell
mdw version
```

### 4. Kullanılabilir komutları görüntüleyin

```powershell
mdw
```

### 5. Geliştirme ortamınızı kontrol edin

```powershell
mdw doctor
```

### 6. Yeni bir eklenti oluşturun

```powershell
mdw new my-plugin
```

### 7. Eklentiyi derleyin

```powershell
mdw build my-plugin
```

### 8. Yayın paketini oluşturun

```powershell
mdw release my-plugin
```

---

### Tipik Geliştirme Akışı

```text
Eklenti Oluştur
       │
       ▼
Doğrula
       │
       ▼
Build
       │
       ▼
ZIP
       │
       ▼
Release
       │
       ▼
Yayınla
```

MDW, tüm WordPress eklenti geliştirme sürecini tek ve tutarlı bir komut satırı deneyimi altında birleştirir.

## Özellikler

### Workspace Intelligence

- Standart WordPress geliştirme çalışma alanı
- Otomatik çalışma alanı doğrulaması
- Merkezi yapılandırma yönetimi

---

### Build Pipeline

- Temiz production build oluşturma
- Geliştirme dosyalarını otomatik hariç tutma
- Production'a hazır klasör yapısı

---

### Doğrulama

- Workspace doğrulaması
- Ortam doğrulaması
- Eklenti yapısı doğrulaması
- WordPress Plugin Check entegrasyonu

---

### Release Pipeline

- Otomatik yedekleme
- Otomatik build
- ZIP paketi oluşturma
- Release paketi hazırlama

---

### Git Entegrasyonu

- Repository durumu
- Branch bilgileri
- Repository doğrulaması
- Git iş akışı desteği

---

### LocalWP Entegrasyonu

- LocalWP kurulumlarını algılama
- Workspace keşfi
- Yerel geliştirme desteği

---

### Test Altyapısı

- Yerleşik test paketi
- Komut doğrulamaları
- Servis doğrulamaları

---

### Uyumluluk

- Windows
- PowerShell 5.1
- PowerShell 7+
- WordPress eklenti geliştirme

## Ekran Görüntüleri

Aşağıdaki ekran görüntüleri doğrudan MDW Toolkit çalıştırılarak alınmıştır.

### Ana Ekran

![MDW Ana Ekran](assets/screenshots/01-home.png)

---

### Temel CLI Deneyimi

| Çalışma Alanı | Build |
|--------------|-------|
| ![](assets/screenshots/04-info.png) | ![](assets/screenshots/07-build.png) |

| Doctor | Release |
|--------|---------|
| ![](assets/screenshots/03-doctor.png) | ![](assets/screenshots/09-release.png) |

| Plugin Check | Git |
|--------------|-----|
| ![](assets/screenshots/06-plugin-check.png) | ![](assets/screenshots/10-git.png) |

## Demo

MDW Toolkit'in çalışma alanı doğrulamasından release paketinin oluşturulmasına kadar olan gerçek CLI iş akışını izleyin.

### İş Akışı

```text
Workspace
    │
    ▼
Doctor
    │
    ▼
Plugin Check
    │
    ▼
Build
    │
    ▼
ZIP
    │
    ▼
Release
    │
    ▼
Git
```

📹 **MDW Toolkit v1.0 Demo**

Gerçek bir WordPress eklentisi üzerinde uçtan uca MDW Toolkit iş akışı.

▶️ **Demo videosunu izle / indir**

[MDW Toolkit v1.0 Demo](assets/demo/mdw-demo-v1.0.0.mp4)

> Tarayıcınız videoyu doğrudan oynatmıyorsa bağlantıya tıklayarak indirebilirsiniz. GitHub README içerisinde MP4 videolarını doğrudan oynatmaz. v1.0.0 GitHub Release oluşturulduktan sonra bu yol Release varlığına veya yayınlanan video bağlantısına dönüştürülecektir.

## Komut Özeti

| Komut | Açıklama |
|--------|----------|
| `mdw` | Ana kontrol panelini görüntüler |
| `mdw version` | Toolkit sürümünü gösterir |
| `mdw help` | Yardım bilgilerini görüntüler |
| `mdw info` | Çalışma alanı bilgilerini gösterir |
| `mdw doctor` | Geliştirme ortamını doğrular |
| `mdw check <plugin>` | WordPress eklentisini doğrular |
| `mdw plugin-check <plugin>` | WordPress Plugin Check çalıştırır |
| `mdw build <plugin>` | Production build oluşturur |
| `mdw zip <plugin>` | Release ZIP paketi oluşturur |
| `mdw release <plugin>` | Tüm release sürecini çalıştırır |
| `mdw git` | Git komutlarını çalıştırır |
| `mdw local` | LocalWP entegrasyonunu yönetir |

---

### Tipik İş Akışı

```text
mdw doctor
        │
        ▼
mdw check my-plugin
        │
        ▼
mdw plugin-check my-plugin
        │
        ▼
mdw build my-plugin
        │
        ▼
mdw zip my-plugin
        │
        ▼
mdw release my-plugin
```

Komutların ayrıntılı açıklamaları ve kullanım örnekleri için **docs/** klasöründeki dokümantasyonu inceleyebilirsiniz.

## Dokümantasyon

Kapsamlı dokümantasyon **docs/** klasörü altında bulunmaktadır.

| Doküman | Açıklama |
|---------|----------|
| [Mimari](docs/architecture.md) | MDW mimarisine genel bakış |
| [CLI](docs/cli.md) | Komut satırı arayüzü |
| [Komutlar](docs/commands.md) | Tüm komutların referansı |
| [Yapılandırma](docs/configuration.md) | Yapılandırma seçenekleri |
| [Workspace](docs/workspace.md) | Çalışma alanı yapısı ve standartları |
| [Build](docs/build.md) | Build Pipeline |
| [Release](docs/release.md) | Release Pipeline |
| [Test](docs/testing.md) | Test altyapısı |
| [SSS](docs/faq.md) | Sık Sorulan Sorular |
| [Yol Haritası](docs/roadmap.md) | Proje yol haritası |

---

### Diğer Repository Dokümanları

- [Katkıda Bulunma Rehberi](CONTRIBUTING.md)
- [Davranış Kuralları](CODE_OF_CONDUCT.md)
- [Güvenlik Politikası](SECURITY.md)
- [Destek](SUPPORT.md)
- [Değişiklik Geçmişi](CHANGELOG.md)
- [Lisans](LICENSE)

## Workspace Yapısı

MDW, tüm WordPress projelerini düzenli, tekrar edilebilir ve sürdürülebilir hale getirmek için standart bir çalışma alanı yapısı kullanır.

```text
C:\
└── Workspace
    ├── Build
    ├── Plugins
    │   ├── plugin-one
    │   ├── plugin-two
    │   └── ...
    ├── Releases
    ├── Local Sites
    ├── Test Data
    ├── Workspace Backup
    └── mdw-toolkit
```

### Workspace Dizinleri

| Dizin | Açıklama |
|-------|----------|
| `Build` | Production build çıktıları |
| `Plugins` | WordPress eklenti geliştirme projeleri |
| `Releases` | Hazır release ZIP paketleri |
| `Local Sites` | LocalWP WordPress siteleri |
| `Test Data` | Test eklentileri ve örnek veriler |
| `Workspace Backup` | Otomatik yedekleme dizini |
| `mdw-toolkit` | MDW Toolkit kaynak kodu |

---

### Geliştirme İş Akışı

```text
Workspace
      │
      ▼
Eklenti Oluştur
      │
      ▼
Doğrula
      │
      ▼
Build
      │
      ▼
ZIP
      │
      ▼
Release
```

Standart çalışma alanı yapısı, projelerin düzenli, tutarlı ve kolay yönetilebilir olmasını sağlar.

## Yol Haritası

MDW Toolkit, kilometre taşı (milestone) odaklı bir geliştirme planı izlemektedir.

### Sürüm 1.x

- Profesyonel CLI altyapısı
- Workspace Intelligence
- Build Pipeline
- ZIP Pipeline
- Release Pipeline
- Eklenti doğrulama
- WordPress Plugin Check entegrasyonu
- Git entegrasyonu
- LocalWP entegrasyonu
- Production seviyesinde dokümantasyon

---

### Gelecek İyileştirmeler

Aşağıdaki başlıklar gelecek sürümler için değerlendirilmektedir.

- Platform desteğinin genişletilmesi
- Gelişmiş test araçları
- Yeni geliştirme komutları
- Workspace şablonları
- CI/CD iyileştirmeleri
- Gelişmiş tanılama araçları
- Performans optimizasyonları

---

Yol haritası; proje hedefleri, bakım ihtiyaçları ve topluluk geri bildirimleri doğrultusunda güncellenmektedir.

---

# Katkıda Bulunma

Katkılarınızı memnuniyetle karşılıyoruz.

Issue veya Pull Request göndermeden önce aşağıdaki belgeleri incelemenizi öneririz.

- [Katkıda Bulunma Rehberi](CONTRIBUTING.md)
- [Davranış Kuralları](CODE_OF_CONDUCT.md)

---

# Hata Bildirimi

Bir hata bulduysanız veya yeni bir özellik önermek istiyorsanız GitHub Issue şablonlarını kullanabilirsiniz.

- Bug Report
- Feature Request

---

# Güvenlik

Bir güvenlik açığı tespit ettiyseniz lütfen aşağıdaki belgeyi takip ederek sorumlu bildirim sürecini uygulayın.

- [Güvenlik Politikası](SECURITY.md)

---

# Destek

MDW Toolkit kullanımıyla ilgili yardıma ihtiyacınız varsa aşağıdaki kaynaklara göz atabilirsiniz.

- [Destek Rehberi](SUPPORT.md)
- [Sık Sorulan Sorular](docs/faq.md)

---

# Lisans

MDW Toolkit, **MIT Lisansı** ile yayımlanmaktadır.

Ayrıntılar için [LICENSE](LICENSE) dosyasına bakabilirsiniz.

---

# Proje Durumu

**Mevcut Sürüm**

**v1.0.0**

Profesyonel WordPress eklenti geliştirme süreçleri için production seviyesinde CLI aracı.

---

PowerShell ile ❤️ geliştirilmiştir.

