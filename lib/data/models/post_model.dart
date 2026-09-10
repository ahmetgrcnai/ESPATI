import 'package:cloud_firestore/cloud_firestore.dart';

/// ESPATI sosyal akışındaki bir gönderiyi temsil eder.
///
/// Pati sistemi iki ayrı alanla tutulur:
///   • [patiCount]   — Firestore'da atomik artış/azalış için `FieldValue.increment`
///   • [patiUserIds] — Aynı kullanıcının iki kez pati'lemesini önleyen uid listesi
///
/// Bu iki alan her zaman senkronize tutulur; güncelleme yalnızca
/// [FirestorePostRepository.togglePati] içindeki transaction üzerinden yapılır.
class PostModel {
  final String id;

  /// Gönderiyi paylaşan kullanıcının Firebase Auth UID'si.
  final String authorId;

  /// Gönderiyi paylaşan kullanıcının görünen adı.
  final String authorName;

  /// Gönderiyi paylaşan kullanıcının profil fotoğrafı URL'si.
  final String authorImage;

  /// Gönderiye bağlı pati'nin Firestore doküman ID'si.
  /// Boş string: gönderi belirli bir pati'ye bağlı değil (ör. genel bir içerik).
  final String petId;

  /// Gönderideki pati'nin adı — UI'da yazar adının yanında rozet olarak gösterilir.
  /// Boş string: gönderi belirli bir pati'ye bağlanmamış (ör. genel bir içerik).
  final String petName;

  /// Pati'nin cinsi — ör. "Golden Retriever", "British Shorthair".
  /// Arama ve cins-bazlı filtreleme için denormalize edilmiş (post dokümanında kopyadır).
  final String petBreed;

  /// Pati'nin türü — [PetType.name] (ör. "dog", "cat"). Boş string = belirsiz.
  /// Denormalize edilmiştir; liste/feed sorgularında ekstra okuma gerekmez.
  final String petType;

  /// Gönderi fotoğrafının Firebase Storage download URL'si.
  final String imageUrl;

  /// Gönderi açıklaması / caption.
  final String description;

  /// Eskişehir ilçe adı (ör. "Odunpazarı", "Tepebaşı", "Sazova Parkı").
  final String location;

  /// Gönderinin paylaşıldığı zaman — Firestore'dan [Timestamp] olarak okunur.
  final DateTime timestamp;

  /// Toplam pati (beğeni) sayısı — Firestore'da `FieldValue.increment` ile güncellenir.
  final int patiCount;

  /// Pati veren kullanıcıların UID listesi — idempotent toggle için kullanılır.
  final List<String> patiUserIds;

  /// Yorum sayısı — UI gösterimi için tutulur.
  final int commentsCount;

  /// Geçerli kullanıcının bu gönderiyi kaydedip kaydetmediği.
  ///
  /// Firestore'a yazılmaz; [SocialViewModel] tarafından yönetilen
  /// istemci taraflı geçici alandır.
  final bool isBookmarked;

  /// Bu gönderinin yönlendirildiği topluluk grubu (Topluluk / Sub-Reddit
  /// mimarisi). `null` = yönlendirilmemiş — feed filtreleri bunu "Genel"
  /// olarak ele alır, literal bir sentinel string yazılmaz.
  final String? groupId;

  /// AI içerik moderasyonu kapısı (Madde 8 — güvenlik direktifi). Bir
  /// moderasyon geçişi bu gönderiyi açıkça işaretlemedikçe `true`'dur; feed
  /// ekranları yalnızca bu alan `true` olan öğeleri göstermelidir.
  /// Varsayılan `true`: moderasyondan önce yazılmış eski gönderiler
  /// görünmeye devam eder — oluşturma akışındaki
  /// [ContentModerationService] kapısı zaten kötü metni Firestore'a hiç
  /// ulaşamadan istemci tarafında reddeder.
  final bool isApproved;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.imageUrl,
    required this.description,
    required this.location,
    required this.timestamp,
    this.petId = '',
    this.petName = '',
    this.petBreed = '',
    this.petType = '',
    this.patiCount = 0,
    this.patiUserIds = const [],
    this.commentsCount = 0,
    this.isBookmarked = false,
    this.groupId,
    this.isApproved = true,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FACTORY CONSTRUCTORS
  // ─────────────────────────────────────────────────────────────────────────

  /// UI'da null-safety sağlamak için boş/placeholder bir PostModel döner.
  factory PostModel.empty() => PostModel(
        id: '',
        authorId: '',
        authorName: '',
        authorImage: '',
        imageUrl: '',
        description: '',
        location: '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        petId: '',
        petName: '',
        petBreed: '',
        petType: '',
      );

  /// Firestore dokümanından [PostModel] oluşturur.
  ///
  /// Kritik: Firestore [Timestamp] → Dart [DateTime] dönüşümü burada yapılır.
  /// [data['timestamp']] alanı hiçbir zaman String veya int olarak gelmez;
  /// Firestore SDK bunu her zaman [Timestamp] tipiyle sunar.
  /// Defensive cast kullanılarak tip hatası önlenir.
  factory PostModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorImage: data['authorImage'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      petId: data['petId'] as String? ?? '',
      petName: data['petName'] as String? ?? '',
      petBreed: data['petBreed'] as String? ?? '',
      petType: data['petType'] as String? ?? '',
      patiCount: data['patiCount'] as int? ?? 0,
      patiUserIds: List<String>.from(
        data['patiUserIds'] as List<dynamic>? ?? const [],
      ),
      commentsCount: data['commentsCount'] as int? ?? 0,
      groupId: data['groupId'] as String?,
      isApproved: data['isApproved'] as bool? ?? true,
    );
  }

  /// REST API / JSON yanıtından [PostModel] oluşturur.
  ///
  /// [timestamp] hem ISO-8601 String hem de millisecondsSinceEpoch int
  /// formatını kabul eder.
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorImage: json['authorImage'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      timestamp: _parseDateTimeJson(json['timestamp']),
      petId: json['petId'] as String? ?? '',
      petName: json['petName'] as String? ?? '',
      petBreed: json['petBreed'] as String? ?? '',
      petType: json['petType'] as String? ?? '',
      patiCount: json['patiCount'] as int? ?? 0,
      patiUserIds: List<String>.from(
        json['patiUserIds'] as List<dynamic>? ?? const [],
      ),
      commentsCount: json['commentsCount'] as int? ?? 0,
      groupId: json['groupId'] as String?,
      isApproved: json['isApproved'] as bool? ?? true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERIALIZATION
  // ─────────────────────────────────────────────────────────────────────────

  /// Firestore'a yazmak için uygun Map döner.
  ///
  /// • Belge ID'si Firestore tarafında tutulduğundan [id] dahil edilmez.
  /// • [timestamp] Firestore [Timestamp]'e dönüştürülür — string değil.
  /// • Yeni gönderi oluştururken [imageUrl] henüz boş olabilir;
  ///   Storage yüklemesi tamamlandıktan sonra [copyWith] ile güncellenir.
  Map<String, dynamic> toFirestore() => {
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'imageUrl': imageUrl,
        'description': description,
        'location': location,
        'timestamp': Timestamp.fromDate(timestamp),
        'petId': petId,
        'petName': petName,
        'petBreed': petBreed,
        'petType': petType,
        'patiCount': patiCount,
        'patiUserIds': patiUserIds,
        'commentsCount': commentsCount,
        'groupId': groupId,
        'isApproved': isApproved,
      };

  /// REST API için JSON Map döner — timestamp ISO-8601 string olarak yazılır.
  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorImage': authorImage,
        'imageUrl': imageUrl,
        'description': description,
        'location': location,
        'timestamp': timestamp.toIso8601String(),
        'petId': petId,
        'petName': petName,
        'petBreed': petBreed,
        'petType': petType,
        'patiCount': patiCount,
        'patiUserIds': patiUserIds,
        'commentsCount': commentsCount,
        'groupId': groupId,
        'isApproved': isApproved,
      };

  // ─────────────────────────────────────────────────────────────────────────
  // COPY WITH
  // ─────────────────────────────────────────────────────────────────────────

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorImage,
    String? imageUrl,
    String? description,
    String? location,
    DateTime? timestamp,
    String? petId,
    String? petName,
    String? petBreed,
    String? petType,
    int? patiCount,
    List<String>? patiUserIds,
    int? commentsCount,
    bool? isBookmarked,
    String? groupId,
    bool? isApproved,
  }) =>
      PostModel(
        id: id ?? this.id,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorImage: authorImage ?? this.authorImage,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
        location: location ?? this.location,
        timestamp: timestamp ?? this.timestamp,
        petId: petId ?? this.petId,
        petName: petName ?? this.petName,
        petBreed: petBreed ?? this.petBreed,
        petType: petType ?? this.petType,
        patiCount: patiCount ?? this.patiCount,
        patiUserIds: patiUserIds ?? this.patiUserIds,
        commentsCount: commentsCount ?? this.commentsCount,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        groupId: groupId ?? this.groupId,
        isApproved: isApproved ?? this.isApproved,
      );

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  String toString() =>
      'PostModel(id: $id, authorName: $authorName, location: $location)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Firestore'dan gelen [Timestamp] veya null değerini güvenle [DateTime]'a çevirir.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    // Yedek: eski dokümanlar string veya int timestamp tutuyorsa bozulmadan okur.
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// JSON'dan gelen timestamp değerini [DateTime]'a çevirir (REST API).
  static DateTime _parseDateTimeJson(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
