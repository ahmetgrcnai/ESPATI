import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LISTINGS SCREEN — Kayıp (Lost) & Sahiplendirme (Adoption) pet cards
// ─────────────────────────────────────────────────────────────────────────────

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          'İlanlar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: cs.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _showPostDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('İlan Ver',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.softTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Kayıp veya sahiplendirme ara...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: cs.onSurface.withOpacity(0.4), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── Tab bar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surface
                    : AppColors.peachLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.softTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: cs.onSurface.withOpacity(0.5),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Tümü'),
                  Tab(text: 'Kayıp'),
                  Tab(text: 'Sahiplendir'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Tab views ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ListingList(
                  items: _kAllListings,
                  isDark: isDark,
                ),
                _ListingList(
                  items: _kAllListings
                      .where((e) => e['status'] == 'kayip')
                      .toList(),
                  isDark: isDark,
                ),
                _ListingList(
                  items: _kAllListings
                      .where((e) => e['status'] == 'sahiplendirme')
                      .toList(),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('İlan oluşturma yakında açılacak!'),
        backgroundColor: AppColors.softTeal,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _ListingList extends StatelessWidget {
  final List<Map<String, String>> items;
  final bool isDark;

  const _ListingList({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64,
                color: AppColors.softTeal.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'Bu kategoride ilan yok',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _ListingCard(item: items[index], isDark: isDark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final Map<String, String> item;
  final bool isDark;

  const _ListingCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLost = item['status'] == 'kayip';
    final statusColor = isLost ? AppColors.error : const Color(0xFFE65100);
    final statusLabel = isLost ? 'Kayıp' : 'Sahiplendirme';
    final statusIcon = isLost ? Icons.search_rounded : Icons.favorite_rounded;
    final cardColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Pet photo ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18)),
            child: CachedNetworkImage(
              imageUrl: item['image']!,
              width: 110,
              height: 130,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 110,
                height: 130,
                color: AppColors.peachLight,
                child: Icon(Icons.pets,
                    size: 40, color: AppColors.peach.withOpacity(0.5)),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 110,
                height: 130,
                color: AppColors.peachLight,
                child: Icon(Icons.pets, size: 40, color: AppColors.peach),
              ),
            ),
          ),

          // ── Info ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Name + breed
                  Text(
                    item['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    item['type']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? Colors.white : AppColors.textPrimary)
                          .withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 13, color: AppColors.softTeal),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item['location']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.softTeal,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date + call button row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 12,
                          color: (isDark ? Colors.white : AppColors.textPrimary)
                              .withOpacity(0.4)),
                      const SizedBox(width: 3),
                      Text(
                        item['date']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: (isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)
                              .withOpacity(0.4),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Aranıyor: ${item['contact']}'),
                              backgroundColor: AppColors.softTeal,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.softTeal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.phone_rounded,
                                  size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Ara',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, String>> _kAllListings = [
  // ── Kayıp ilanları ──
  {
    'status': 'kayip',
    'name': 'Rocky',
    'type': 'Golden Retriever',
    'location': 'Odunpazarı, Eskişehir',
    'date': '15 Mar 2026',
    'image': 'https://placekitten.com/400/400',
    'contact': '0532 555 01 01',
    'description': '3 yaşında erkek, kırmızı tasmalı. Odunpazarı civarında son görüldü.',
  },
  {
    'status': 'kayip',
    'name': 'Mimi',
    'type': 'Tekir Kedi',
    'location': 'Tepebaşı, Eskişehir',
    'date': '14 Mar 2026',
    'image': 'https://placekitten.com/401/401',
    'contact': '0533 555 02 02',
    'description': 'Küçük dişi kedi, gri çizgili. Çok ürkek.',
  },
  {
    'status': 'kayip',
    'name': 'Karamel',
    'type': 'Fransız Bulldog',
    'location': 'Eskişehir Merkez',
    'date': '13 Mar 2026',
    'image': 'https://placekitten.com/402/402',
    'contact': '0534 555 03 03',
    'description': '2 yaşında erkek, kahverengi bej renkli. Mavi tasmalı.',
  },
  {
    'status': 'kayip',
    'name': 'Snowball',
    'type': 'Ankara Kedisi',
    'location': 'Bağlar, Eskişehir',
    'date': '12 Mar 2026',
    'image': 'https://placekitten.com/403/403',
    'contact': '0535 555 04 04',
    'description': 'Uzun tüylü, mavi gözlü beyaz kedi.',
  },

  // ── Sahiplendirme ilanları ──
  {
    'status': 'sahiplendirme',
    'name': 'Pamuk',
    'type': 'Beyaz Kedi',
    'location': 'Tepebaşı, Eskişehir',
    'date': '10 Mar 2026',
    'image': 'https://placekitten.com/404/404',
    'contact': '0536 555 05 05',
    'description': '1.5 yaşında dişi, aşıları tam. Çok uysal ve sevecen.',
  },
  {
    'status': 'sahiplendirme',
    'name': 'Zeytin',
    'type': 'Labrador Mix',
    'location': 'Odunpazarı, Eskişehir',
    'date': '9 Mar 2026',
    'image': 'https://placekitten.com/405/405',
    'contact': '0537 555 06 06',
    'description': '4 aylık yavru, aşılar yaptırıldı. Yuva arıyor.',
  },
  {
    'status': 'sahiplendirme',
    'name': 'Fındık',
    'type': 'Sarman Kedi',
    'location': 'Porsuk, Eskişehir',
    'date': '8 Mar 2026',
    'image': 'https://placekitten.com/406/406',
    'contact': '0538 555 07 07',
    'description': '2 yaşında erkek, kısırlaştırıldı, aşılar tam.',
  },
  {
    'status': 'sahiplendirme',
    'name': 'Boncuk',
    'type': 'Tavşan (Hollandalı)',
    'location': 'Merkez, Eskişehir',
    'date': '7 Mar 2026',
    'image': 'https://placekitten.com/407/407',
    'contact': '0539 555 08 08',
    'description': '1 yaşında dişi tavşan, kafes ve aksesuarlar dahil.',
  },
];
