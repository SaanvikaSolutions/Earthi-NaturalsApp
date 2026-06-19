import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../data/mock/mock_data.dart';
import 'collection_list_screen.dart';

/// Collection tab — a curated browse landing: featured collections, category
/// shortcuts, concerns, category & ingredient icon grids, and a CTA into the
/// full catalogue.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  static const _collectionCards = <_CardItem>[
    _CardItem('New Arrival', 'assets/images/col_newarrival.png',
        CollectionKind.newArrival),
    _CardItem('Bestseller', 'assets/images/col_bestseller.png',
        CollectionKind.bestseller),
    _CardItem('Top Rated', 'assets/images/col_toprated.png',
        CollectionKind.topRated),
    _CardItem('Discount', 'assets/images/col_discount.png',
        CollectionKind.discount),
  ];

  static const _categoryRows = <_RowItem>[
    _RowItem('Skin Care', 'assets/images/cat_skincare_lg.png', 'Skin care'),
    _RowItem('Hair Care', 'assets/images/cat_haircare_lg.png', 'Hair care'),
    _RowItem('Baby Care', 'assets/images/cat_babycare_lg.png', 'Baby Care'),
  ];

  static const _catIcons = <_IconItem>[
    _IconItem('Serum', 'assets/images/ic_serum.png'),
    _IconItem('Face Cream', 'assets/images/ic_facecream.png'),
    _IconItem('Face Wash', 'assets/images/ic_facewash.png'),
    _IconItem('Lotion', 'assets/images/ic_lotion.png'),
    _IconItem('Face Gel', 'assets/images/ic_facegel.png'),
    _IconItem('Hair Fall', 'assets/images/ic_hairfall.png'),
    _IconItem('Eye Cream', 'assets/images/ic_eyecream.png'),
    _IconItem('Lip Balm', 'assets/images/ic_lipbalm.png'),
    _IconItem('Face Pack', 'assets/images/ic_facepack.png'),
    _IconItem('Shampoo', 'assets/images/ic_shampoo.png'),
  ];

  static const _ingredients = <_IconItem>[
    _IconItem('Aloe Vera', 'assets/images/ic_serum.png'),
    _IconItem('Hibiscus', 'assets/images/ic_facecream.png'),
    _IconItem('Neem', 'assets/images/ic_facewash.png'),
    _IconItem('Rose', 'assets/images/ic_lotion.png'),
    _IconItem('Saffron', 'assets/images/ic_facegel.png'),
  ];

  static const _serif = 'Georgia';

  void _browseAll(BuildContext context, [String category = 'All']) =>
      context.push('/all-products', extra: category);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _topBar(context),
            const SizedBox(height: 4),
            _heading('Our Collections'),
            const SizedBox(height: 14),
            _collectionRow(context),
            const SizedBox(height: 22),
            ..._categoryRows.map((r) => _categoryRow(context, r)),
            const SizedBox(height: 18),
            _heading('Shop by concern'),
            const SizedBox(height: 14),
            _concerns(context),
            const SizedBox(height: 26),
            _heading('Shop by category'),
            const SizedBox(height: 14),
            _categoryIconCard(context),
            const SizedBox(height: 26),
            _heading('Ingredients'),
            const SizedBox(height: 14),
            _ingredientCard(context),
            const SizedBox(height: 26),
            _ctaBanner(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Gap.pagePadding, 4, 8, 8),
        child: Row(
          children: [
            const BrandLogo(width: 120),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none)),
            IconButton(
                onPressed: () => context.push('/wishlist'),
                icon: const Icon(Icons.favorite_border)),
          ],
        ),
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: _serif,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  // ---- Our Collections: four image cards across the row. ----
  Widget _collectionRow(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        child: Row(
          children: [
            for (var i = 0; i < _collectionCards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/collection-list',
                      extra: _collectionCards[i].kind),
                  child: AspectRatio(
                    aspectRatio: 160 / 182,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(_collectionCards[i].asset,
                          fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  // ---- Category list rows: photo • label • chevron, divided. ----
  Widget _categoryRow(BuildContext context, _RowItem r) => Column(
        children: [
          InkWell(
            onTap: () => context.push('/category', extra: r.category),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Gap.pagePadding, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(r.asset,
                        width: 86, height: 86, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    r.label,
                    style: const TextStyle(
                      fontFamily: _serif,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 28, color: AppColors.textPrimary),
                ],
              ),
            ),
          ),
          const Divider(
              height: 1, thickness: 1, indent: Gap.pagePadding,
              endIndent: Gap.pagePadding, color: AppColors.divider),
        ],
      );

  // ---- Shop by concern: horizontal photo tiles. ----
  Widget _concerns(BuildContext context) => SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          itemCount: MockData.concerns.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _browseAll(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(MockData.concernIcons[i],
                      width: 120, height: 120, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 120,
                  child: Text(MockData.concerns[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      );

  // ---- Shop by category: green gradient card, 2×5 circular icons. ----
  Widget _categoryIconCard(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF365E50), Color(0xFFACEEC9)],
            ),
          ),
          child: Column(
            children: [
              _iconRow(context, _catIcons.sublist(0, 5), Colors.white),
              const SizedBox(height: 18),
              _iconRow(context, _catIcons.sublist(5, 10), Colors.white),
            ],
          ),
        ),
      );

  // ---- Ingredients: olive card, single row of circular icons. ----
  Widget _ingredientCard(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF6B6030),
          ),
          child: _iconRow(context, _ingredients, Colors.white),
        ),
      );

  Widget _iconRow(BuildContext context, List<_IconItem> items, Color textColor) =>
      Row(
        children: [
          for (final it in items)
            Expanded(
              child: GestureDetector(
                onTap: () => _browseAll(context),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(it.asset,
                          width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                    Text(it.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                  ],
                ),
              ),
            ),
        ],
      );

  // ---- "Still searching?" CTA. ----
  Widget _ctaBanner(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFFD8E2D7),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: Image.asset('assets/images/cta_leaves.png',
                  width: 120, fit: BoxFit.contain),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Still searching?\nExplore our complete\ncollection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: _serif,
                        fontSize: 24,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Image.asset('assets/images/cta_illustration.png',
                        width: 150),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => _browseAll(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlack,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                        child: const Text('Browse All Products',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _CardItem {
  final String label;
  final String asset;
  final CollectionKind kind;
  const _CardItem(this.label, this.asset, this.kind);
}

class _RowItem {
  final String label;
  final String asset;
  final String category;
  const _RowItem(this.label, this.asset, this.category);
}

class _IconItem {
  final String label;
  final String asset;
  const _IconItem(this.label, this.asset);
}
