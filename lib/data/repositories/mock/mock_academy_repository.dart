import 'package:flutter/material.dart';
import '../../../core/result.dart';
import '../../models/academy_guide_model.dart';
import '../interfaces/i_academy_repository.dart';

/// Mock implementation of [IAcademyRepository].
///
/// Contains 7 professionally written Turkish guides with rich Markdown content.
/// Simulates a short network fetch delay. Swap for a real API when ready.
class MockAcademyRepository implements IAcademyRepository {
  static const _delay = Duration(milliseconds: 600);

  static final List<AcademyGuideModel> _guides = [
    // ── 1. Yeni Sahip — İlk Hafta ────────────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_001',
      category: AcademyCategory.yeniSahip,
      categoryLabel: 'Yeni Sahip',
      title: 'Yeni Kedi/Köpek Sahibi İçin İlk Hafta Rehberi',
      summary:
          'Eve yeni gelen tüylü dostunuzla ilk 7 günü sağlıklı ve stressiz geçirmek için adım adım rehber.',
      icon: Icons.home_rounded,
      accentColor: const Color(0xFF4DB6AC), // softTeal
      readMinutes: 7,
      contentMarkdown: '''
# Yeni Tüylü Dostunuzla İlk Hafta

Yeni bir evcil hayvanı eve getirmek hem heyecan verici hem de biraz stresli olabilir — hem sizin hem de dostunuz için! Bu rehber, alışma sürecini mümkün olduğu kadar sorunsuz geçirmenize yardımcı olacak.

---

## Gün 1–2: Güvenli Alan Oluşturma

İlk günlerde **küçük bir alandan başlayın**. Tüm evi birden keşfettirmeye çalışmak yeni gelene bunaltıcı gelebilir.

- 🏠 Tek bir odayı "karşılama odası" olarak belirleyin
- Yiyecek, su ve tuvalet kabını bu odaya koyun
- Saklanabileceği bir yer hazırlayın (kutu, battaniye altı)
- Sakin bir ses tonuyla konuşun; ani hareketlerden kaçının

> **İpucu:** Kediler için kedi taşıyıcısını açık bırakın — tanıdık kokusu onları sakinleştirir.

---

## Gün 3–4: İlk Veteriner Ziyareti

Eve geldikten sonraki **48–72 saat içinde** bir veterinere götürün.

**Kontrol listesi:**
- [ ] Genel sağlık muayenesi
- [ ] Aşı durumu kontrolü
- [ ] Parazit taraması (iç ve dış)
- [ ] Kısırlaştırma/sterilizasyon planlaması (henüz yapılmamışsa)

---

## Gün 5–6: Ev Kurallarını Belirleme

Tutarlılık şarttır. Tüm aile üyeleri aynı kurallara uymalıdır:

| Davranış | Yapılacak |
|---|---|
| Mobilyaya tırmalamak/ısırmak | Alternatif sunun (tırmalama tahtası, oyuncak) |
| Yemek masasına atlamak | Tutarlı biçimde "yok" deyin |
| Kendi yatağında uyumak | Rahat bir yatak hazırlayın |

---

## Gün 7: Serbest Keşif

Hayvanınız artık temel alana alıştıysa, kapsamı yavaşça genişletin.

- Kapıları birer birer açın
- Gözetim altında keşfetmesine izin verin
- Stres belirtilerini izleyin: saklanma, iştahsızlık, aşırı tımar

---

## Nelere Dikkat Etmeli?

**Acil veteriner gerektiren belirtiler:**
- 24 saatten fazla yememek/içmemek
- Kanlı dışkı veya kusma
- Nefes darlığı
- Aşırı letarji

---

*Sabırlı olun — çoğu evcil hayvan 2–4 hafta içinde tam anlamıyla uyum sağlar.*
''',
    ),

    // ── 2. Köpek Eğitimi — Tuvalet ───────────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_002',
      category: AcademyCategory.kopekEgitimi,
      categoryLabel: 'Köpek Eğitimi',
      title: 'Adım Adım Köpek Tuvalet Eğitimi',
      summary:
          'Pozitif pekiştirme yöntemiyle köpeğinizi 2–4 haftada tuvalet eğitimine alıştırın.',
      icon: Icons.directions_walk_rounded,
      accentColor: const Color(0xFFFFB6A0), // peach
      readMinutes: 6,
      contentMarkdown: '''
# Adım Adım Köpek Tuvalet Eğitimi

Tuvalet eğitimi sabır, tutarlılık ve bol ödülden ibarettir. Ceza yöntemi köpekler için etkisizdir ve güveni zedeler — bu rehberde yalnızca **pozitif pekiştirme** kullanacağız.

---

## Temel Prensip: Zamanlama

Köpekler genellikle şu anlarda tuvalete çıkmak ister:

- Uyandıktan hemen sonra
- Her yemekten 15–20 dakika sonra
- Yoğun oyundan sonra
- Her 2–3 saatte bir (yavru köpekler için daha sık)

---

## Hafta 1: Düzenli Program

**Her gün aynı saatlerde** dışarı veya belirlenen bölgeye götürün.

1. Tasmasını takın ve sessizce bölgeye gidin
2. **5 dakika** bekleyin
3. Tuvalet yaptıysa → **hemen** ödüllendirin (iltifat + oyuncak/mama)
4. Yapmadıysa → eve dönün, 15 dakika sonra tekrar deneyin

> **Kritik:** Ödül tuvalet biter bitmez verilmeli. Gecikmeli ödül etkisizdir.

---

## Hafta 2: "Tuvalet" Komutu

Köpek düzenli tuvalet yapar hale geldikten sonra komut ekleyin:

- Tuvalete başladığı anda sakin sesle **"tuvalet"** deyin
- Birkaç gün sonra komut duyduğunda tuvalete başlayacak

---

## Kaza Olduğunda

**Yapılacaklar:**
- Sakin kalın
- Bölgeyi enzimatik temizleyici ile temizleyin (koku izini kaldırır)
- Neden olduğunu düşünün: program kaçırıldı mı?

**Yapılmayacaklar:**
- ❌ Bağırmak veya yüzünü pisliğe sürtmek
- ❌ Uzun süre sonra ceza vermek (köpek ilişkilendiremez)
- ❌ Pes etmek!

---

## Hız Referansı

| Yaş | Beklenebilir Bekleme Süresi |
|---|---|
| 8–10 hafta | 1–2 saat |
| 3–4 ay | 2–3 saat |
| 6+ ay | 4–6 saat |
| Yetişkin | 6–8 saat |

---

## Apartman İçin Alternatif: Çim Pedi

Dışarı çıkma imkânı sınırlıysa:

- Balkon veya belirli köşeye **köpek çim pedi** yerleştirin
- Komut ve ödül sistemi aynı şekilde işler
- Kokuyu tanıması için ilk pedi değiştirmeden bir gün bekleyin

---

*Çoğu köpek 2–4 hafta içinde öğrenir. Küçük ırklar biraz daha uzun sürebilir.*
''',
    ),

    // ── 3. Kedi Bakımı — Tırmalama ────────────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_003',
      category: AcademyCategory.kediBakimi,
      categoryLabel: 'Kedi Bakımı',
      title: 'Kedilerde Tırmalama Alışkanlığı Nasıl Yönetilir?',
      summary:
          'Mobilyalarınızı korurken kedinizin doğal tırmalama ihtiyacını karşılamasına yardımcı olun.',
      icon: Icons.content_cut_rounded,
      accentColor: const Color(0xFF9C77BD), // purple
      readMinutes: 5,
      contentMarkdown: '''
# Kedilerde Tırmalama Alışkanlığı Nasıl Yönetilir?

Tırmalamak kediler için **tamamen doğal ve gerekli** bir davranıştır. Amacı:
- Tırnak kılıflarını dökmek
- Kasları germek
- Bölge işaretlemek (hem görsel hem koku ile)
- Stres atmak

Hedef tırmalamanın **önüne geçmek değil**, **doğru yere yönlendirmektir**.

---

## Doğru Tırmalama Tahtası Seçimi

Kediler farklı yüzeyleri ve pozisyonları tercih eder. Birkaçını deneyin:

| Tip | Özellik |
|---|---|
| Dikey + Sisal | En yaygın; kedi uzanarak tırmalar |
| Yatay + Oluklu karton | Bazı kediler tercih eder |
| Eğimli + Halı | Orta tercih |
| Kedi ağacı | Hem tırmalama hem zıplama |

> **İpucu:** Tahta, kedinizin tam boy uzanabileceği kadar uzun olmalı.

---

## Nereye Koymalı?

- **Uyku alanının yakınına** — kediler uyandıktan hemen sonra tırmalar
- **Mobilyanın yanına** (tırnadığı yere) — yavaşça uzaklaştırın
- En az **2 farklı konuma** koyun

---

## Mobilyayı Koruma

**Kısa vadeli:**
- Çift taraflı bant — kediler yapışkan yüzeyi sevmez
- Folyo — benzer şekilde caydırıcı
- Koruyucu plastik kapak

**Kalıcı çözüm:**
Tırnak kılıfı (Soft Paws) — aylık olarak değiştirilir, zararsız.

---

## Tırmalamaya Teşvik Etme

1. Tahta yanına kedi nanesi (catnip) serpin
2. Öne geçip tahtayı kendiniz tırmalayın (taklit içgüdüsünü tetikler)
3. Tahtayı kullandığında **hemen ödüllendirin**
4. Mobilyayı tırnadığında sakin sesle **"hayır"** deyin ve tahtaya yönlendirin

---

## Tırnak Kesimi

Düzenli tırnak kesimi tırmalamanın etkisini azaltır:

- Her **2–3 haftada bir** kesin
- Yalnızca **şeffaf kısmı** kesin — pembe damarı kesmekten kaçının
- İlk seferde bir pençe ile başlayın, ödüllendirin

---

*Sabır ve tutarlılık: çoğu kedi 1–2 hafta içinde tahtayı benimseyecektir.*
''',
    ),

    // ── 4. Sağlık — Aşı Takvimi ──────────────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_004',
      category: AcademyCategory.saglik,
      categoryLabel: 'Sağlık',
      title: 'Evcil Hayvanlar İçin Aşı Takvimi',
      summary:
          'Köpek ve kedi aşı takvimleri, hangi aşıların zorunlu olduğu ve hatırlatıcı dozlar hakkında tam rehber.',
      icon: Icons.vaccines_rounded,
      accentColor: const Color(0xFF4CAF50), // green
      readMinutes: 5,
      contentMarkdown: '''
# Evcil Hayvanlar İçin Aşı Takvimi

Aşılama, birçok ölümcül hastalığa karşı korunmanın en etkili yoludur. Veterineriniz bireysel risklere göre programı özelleştirebilir.

---

## Köpek Aşı Takvimi

### Zorunlu (Core) Aşılar

| Aşı | İlk Doz | Hatırlatıcı |
|---|---|---|
| DHPPi (Karma) | 6–8 hafta | 3–4 haftada bir, 16 haftaya kadar |
| Kuduz | 12–16 hafta | 1 yıl sonra, ardından 3 yılda bir |

### İsteğe Bağlı (Non-core) Aşılar

| Aşı | Kimler İçin |
|---|---|
| Leptospiroz | Su kaynağına erişimi olan köpekler |
| Kennel Öksürüğü | Pansiyon/köpek parkı kullanıcıları |
| Lyme | Kene bölgelerinde yaşayanlar |

---

## Kedi Aşı Takvimi

### Zorunlu (Core) Aşılar

| Aşı | İlk Doz | Hatırlatıcı |
|---|---|---|
| FVRCP (Karma) | 6–8 hafta | 3–4 haftada bir, 16 haftaya kadar |
| Kuduz | 12–16 hafta | 1 yıl sonra, ardından 1–3 yılda bir |

### İsteğe Bağlı (Non-core) Aşılar

| Aşı | Kimler İçin |
|---|---|
| FeLV (Lösemi) | Dışarı çıkan kediler |
| FIV | Kavga riski olan kediler |

---

## Yetişkin Hayvan Aşı Takvimi

Aşı geçmişi bilinmiyorsa veterineriniz yeniden başlatabilir.

- **Yıllık kontrol** — aşı ihtiyacı değerlendirilir
- **Titre testi** — kan testi ile bağışıklık düzeyi ölçülür

---

## Aşı Sonrası Normal Belirtiler

- Hafif ateş (24–48 saat)
- İştah azalması
- Enjeksiyon bölgesinde şişlik

**Acil veteriner:** Yüz şişmesi, nefes darlığı, bayılma → Anafilaksi belirtisi.

---

*Aşı kartınızı dijital olarak da saklayın — seyahat ve pansiyon için gerekebilir.*
''',
    ),

    // ── 5. Yeni Sahip — Beslenmek ─────────────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_005',
      category: AcademyCategory.yeniSahip,
      categoryLabel: 'Yeni Sahip',
      title: 'Evcil Hayvanınızı Doğru Besleyin',
      summary:
          'Kedi ve köpekler için temel beslenme rehberi: porsiyon hesaplama, yasaklı gıdalar ve su tüketimi.',
      icon: Icons.restaurant_rounded,
      accentColor: const Color(0xFFFFB300), // amber
      readMinutes: 6,
      contentMarkdown: '''
# Evcil Hayvanınızı Doğru Besleyin

Dengeli beslenme, uzun ve sağlıklı bir yaşamın temelidir. Ne kadar, ne sıklıkta ve ne verdiğiniz büyük fark yaratır.

---

## Köpekler İçin Temel Beslenme

### Günlük Porsiyon

Vücut ağırlığının yaklaşık **%2–3'ü** — mama paketindeki talimatlar başlangıç noktasıdır.

| Ağırlık | Günlük Miktar (kuru mama) |
|---|---|
| 5 kg | 80–110 g |
| 10 kg | 150–200 g |
| 20 kg | 270–350 g |
| 30 kg | 370–480 g |

> Aktif, genç ve gebe hayvanlar daha fazlasına ihtiyaç duyar.

### Öğün Sıklığı

- **Yavru (< 6 ay):** Günde 3–4 öğün
- **Yetişkin:** Günde 2 öğün
- **Yaşlı:** Veteriner önerisine göre

---

## Kediler İçin Temel Beslenme

Kediler **obligat karnivor**dur — bitkisel protein yeterli değildir.

- Kuru mama: Diş sağlığına iyi, pratik
- Yaş mama: Daha fazla su içerir, böbrek sağlığı için faydalı
- **İdeal:** İkisinin kombinasyonu

### Su Tüketimi

Kediler düşük susuzluk hissi ile evrimleşmiştir. Yeterli su alımı için:
- Su çeşmesi (akan su tercih ederler)
- Birden fazla konuma su kabı
- Yaş mama oranını artırın

---

## Kesinlikle Verilmeyecek Gıdalar

### Köpekler İçin Toksik

- 🚫 Çikolata (teobromin)
- 🚫 Üzüm ve kuru üzüm (böbrek yetmezliği)
- 🚫 Soğan ve sarımsak (kan hücresi hasarı)
- 🚫 Ksilitol (ağız sakızı, bazı fıstık ezmeleri)
- 🚫 Avokado (persin)

### Kediler İçin Toksik

- 🚫 Soğan ve sarımsak
- 🚫 Çiğ balık (sürekli verilirse B1 eksikliği)
- 🚫 Çiğ yumurta beyazı
- 🚫 Ksilitol
- 🚫 Alkol

---

## Şişmanlık Uyarısı

Dünya genelinde evcil hayvanların **%50–60'ı** fazla kilolu.

**Kontrol yöntemi:** Kaburgaları dokunarak hissedebilmeli ama görünmemeli.

---

*Diyet değişikliklerini her zaman 7–10 günde yavaşça yapın — ani geçişler sindirim sorununa yol açar.*
''',
    ),

    // ── 6. Köpek Eğitimi — Temel Komutlar ─────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_006',
      category: AcademyCategory.kopekEgitimi,
      categoryLabel: 'Köpek Eğitimi',
      title: '5 Temel Köpek Komutu ve Nasıl Öğretilir?',
      summary:
          '"Otur, Dur, Gel, Yere Yat, Serbest" komutlarını pozitif pekiştirme ile öğretme rehberi.',
      icon: Icons.school_rounded,
      accentColor: const Color(0xFF2196F3), // blue
      readMinutes: 8,
      contentMarkdown: '''
# 5 Temel Köpek Komutu

Bu 5 komut güvenlik ve uyum açısından temeldir. Her biri günde **2–3 kez, 5 dakikalık** seanslarda öğretilmelidir.

---

## Genel Kurallar

- ✅ Kısa seans (5 dk) — dikkat süresi kısadır
- ✅ Yüksek değerli ödül — küçük et parçası, peynir
- ✅ Sakin ortam — dışarı geçmeden önce içeride öğretin
- ❌ Tekrar sayısını körce artırmayın — bıkkınlık öğrenmeyi bloke eder

---

## 1. Otur (Sit)

**En kolay komuttur, buradan başlayın.**

1. Ödülü burnuna yaklaştırın
2. Ödülü yavaşça başının üstüne doğru çekin — kalçası kendiliğinden iner
3. Tam oturduğu anda **"otur"** deyin ve ödüllendirin
4. Birkaç tekrardan sonra ödülü göstermeden önce komutu verin

---

## 2. Dur (Stay)

*Otur* öğrenildikten sonra.

1. Köpeği oturtun
2. Elinizi durma işareti gibi kaldırın, **"dur"** deyin
3. 1 saniye bekleyin → ödüllendirin
4. Her seansta süreyi 1–2 saniye artırın
5. Giderek uzaklaşmaya başlayın

---

## 3. Gel (Come)

**Güvenlik açısından en kritik komuttur.**

1. Tasmasını tutarken **"gel"** deyin ve ona doğru yürüyün
2. Geldiğinde coşkuyla ödüllendirin
3. Tasmasız, kısa mesafeden başlayın
4. Asla "gel" deyip ceza vermeyin — komutu olumsuz çağrışımla mahvetirsiniz

---

## 4. Yere Yat (Down/Uzat)

1. Köpeği oturtun
2. Ödülü burnuna götürün, yavaşça yere doğru indirin
3. Dirsekler yere değdiğinde **"yat"** deyin ve ödüllendirin
4. Komuta hazır hale geldikten sonra ödülü gizleyin

---

## 5. Serbest (Free/Tamam)

Diğer komutların bitişini işaret eder.

- Her seansin sonunda **"serbest"** veya **"tamam"** deyin
- Köpek artık hareket edebilir
- Bu sayede komutların ne zaman bittiğini öğrenir

---

## İlerleme Tablosu

| Hafta | Hedef |
|---|---|
| 1 | Otur güvenilir şekilde çalışıyor |
| 2 | Dur 10 saniye / 1 metre mesafede |
| 3 | Gel 5 metre mesafeden |
| 4 | Yat ve Serbest çalışıyor |

---

*Eğitim hiçbir zaman gerçekten "bitmez" — kısa tekrarlarla ömür boyu sürdürülmelidir.*
''',
    ),

    // ── 7. Sağlık — Aylık Kontrol ─────────────────────────────────────────────
    AcademyGuideModel(
      id: 'guide_007',
      category: AcademyCategory.saglik,
      categoryLabel: 'Sağlık',
      title: 'Evde Aylık Sağlık Kontrolü Nasıl Yapılır?',
      summary:
          'Veterinere gitmeden önce fark etmenizi sağlayacak 10 maddelik aylık ev kontrolü.',
      icon: Icons.health_and_safety_rounded,
      accentColor: const Color(0xFFE91E63), // pink
      readMinutes: 4,
      contentMarkdown: '''
# Evde Aylık Sağlık Kontrolü

Ayda bir kez yapacağınız 10 dakikalık kontrol, sorunları erken tespit etmenizi sağlar.

---

## Kontrol Listesi

### 1. Gözler
- Berrak ve parlak mı?
- Akıntı veya kızarıklık var mı?
- ❗ Sarı/yeşil akıntı → veteriner

### 2. Kulaklar
- İçi temiz ve pembe mi?
- Kötü koku veya kahverengi salgı var mı?
- ❗ Baş sallama, kulak kaşıma → kulak enfeksiyonu olabilir

### 3. Diş ve Diş Etleri
- Diş etleri pembe mi? (koyu kırmızı/beyaz olmamalı)
- Diş taşı (sarı-kahverengi birikinti) var mı?
- ❗ Yemek yemede isteksizlik → ağız ağrısı

### 4. Burun
- Nemliliği değişken olabilir (yalnız aşırı akıntı sorun)
- ❗ Sarı/yeşil akıntı veya kabuklanma → muayene

### 5. Deri ve Tüy
- Pullanma, kızarıklık, aşırı dökülme var mı?
- Tüyler parlak ve temiz mi?
- ❗ Yoğun kaşıntı → alerji veya parazit

### 6. Tırnaklar
- Çok uzamış mı? Zemine çarpıyor mu?
- Kıvrılma var mı?
- 🔧 Gerekirse kesin veya kestirin

### 7. Ağırlık
- Kaburgalar dokunarak hissedilmeli, görünmemeli
- ❗ Hızlı kilo kaybı veya kilo alımı → araştırın

### 8. Dışkı
- Şekli düzgün mü? Rengi normal mi?
- ❗ Kan, mukus veya 48 saati aşan ishal → acil

### 9. Hareketlilik
- Topalama, merdiven çıkmaktan kaçınma var mı?
- ❗ Ani hareketlilik kaybı → eklem veya kas sorunu

### 10. Davranış
- Olağandışı sinirlilik, geri çekilme veya sesli iletişim artışı
- ❗ Ani kişilik değişikliği çoğunlukla sağlık sorununun ilk işaretidir

---

## Hızlı Referans Kart

| Bulgu | Öncelik |
|---|---|
| Berrak burun akıntısı | İzle |
| Hafif kaşıntı (parazit yok) | İzle |
| Sarı/yeşil akıntı (herhangi yer) | Bu hafta veteriner |
| Kan, nefes darlığı, bayılma | Acil veteriner |

---

*Bu kontrolleri bir rutine bağlayın — örneğin her ayın ilk Pazartesi. Düzenlilik, değişiklikleri fark etmenizi kolaylaştırır.*
''',
    ),
  ];

  @override
  Future<Result<List<AcademyGuideModel>>> getGuides() async {
    await Future.delayed(_delay);
    return Success(List.unmodifiable(_guides));
  }

  @override
  Future<Result<AcademyGuideModel>> getGuideById(String id) async {
    await Future.delayed(_delay);
    try {
      final guide = _guides.firstWhere((g) => g.id == id);
      return Success(guide);
    } catch (_) {
      return const Failure('Rehber bulunamadı.');
    }
  }
}
