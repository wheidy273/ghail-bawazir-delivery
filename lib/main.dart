import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;


/// Network images are cached on-device and always have a bundled local fallback.
/// Hybrid image rendering: online photos stay enabled, local assets are fallbacks.
/// Web uses Image.network directly; native platforms retain CachedNetworkImage caching.
class HybridImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final String fallbackAsset;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const HybridImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackAsset = 'assets/images/fallback_food.png',
    this.errorBuilder,
  });

  Widget _fallback(BuildContext context, Object error, StackTrace? stack) {
    if (errorBuilder != null) return errorBuilder!(context, error, stack);
    return const ColoredBox(
      color: Color(0xFFE2F4EC),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Color(0xFF087F5B),
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          fallbackAsset,
          fit: fit,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFE2F4EC),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                color: Color(0xFF087F5B),
                size: 32,
              ),
            ),
          ),
        ),
        if (kIsWeb)
          Image.network(
            url,
            fit: fit,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, sync) {
              if (sync || frame != null) return child;
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stack) =>
                const SizedBox.shrink(),
          )
        else
          Image.network(
            url,
            fit: fit,
            errorBuilder: (context, error, stack) =>
                const SizedBox.shrink(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }
}
void main() => runApp(const GhailDeliveryApp());

const brand = Color(0xFF087F5B);
const ink = Color(0xFF18212B);
const softBg = Color(0xFFF5F7F8);
// Demo bypass is enabled only for debug builds or an explicitly configured preview build.
const _previewSkipEnabled = bool.fromEnvironment('DEMO_AUTH_BYPASS', defaultValue: false);
bool get _canSkipLogin => kDebugMode || _previewSkipEnabled;

class GhailDeliveryApp extends StatelessWidget {
  const GhailDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'غيل باوزير توصيل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: const CardThemeData(color: Colors.white, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: brand),
        scaffoldBackgroundColor: softBg,
        fontFamily: null,
        appBarTheme: const AppBarTheme(
          backgroundColor: softBg,
          foregroundColor: ink,
          centerTitle: false,
        ),
      ),
      home: const StartupGate(),
    );
  }
}


/// Startup flow. Phone verification is intentionally not simulated: it must be
/// connected to a trusted authentication backend before accounts are real.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});
  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1500),
  )..forward();
  bool _showLogin = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _showLogin = true);
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showLogin ? const PhoneLoginScreen(key: ValueKey('login')) : _splash(),
    ),
  );

  Widget _splash() => Scaffold(
    key: const ValueKey('splash'),
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topRight, end: Alignment.bottomLeft,
        colors: [Color(0xFF064E3B), Color(0xFF087F5B), Color(0xFF13A779)],
      )),
      child: SafeArea(child: Center(child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Opacity(
          opacity: _controller.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - _controller.value)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 112, height: 112,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(34),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 28, offset: const Offset(0, 12))]),
                child: const Icon(Icons.delivery_dining_rounded, size: 72, color: brand)),
              const SizedBox(height: 24),
              const Text('غيل باوزير توصيل', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('احتياجاتك اليومية… لحد باب بيتك', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 38),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
            ]),
          ),
        ),
      ))),
    ),
  );
}

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() { _phoneController.dispose(); super.dispose(); }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    // No OTP is sent yet. Never claim authentication succeeded before backend integration.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('واجهة التسجيل جاهزة. سنفعّل إرسال رمز التحقق بعد ربط مزوّد SMS الآمن.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _skipDemo() {
    if (!_canSkipLogin) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(alignment: Alignment.centerRight, child: Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: const Color(0xFFE5F5EE), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.delivery_dining_rounded, color: brand, size: 36),
          )),
          const SizedBox(height: 25),
          Container(
            height: 190,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Color(0xFF075B43), Color(0xFF13A779)])),
            child: Stack(children: [
              Positioned(left: -22, bottom: -45, child: Icon(Icons.circle, size: 190, color: Colors.white.withValues(alpha: .07))),
              Positioned(left: 20, top: 16, child: Icon(Icons.local_shipping_rounded, size: 74, color: Colors.white.withValues(alpha: .16))),
              Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: const [
                Text('أهلًا بك في غيل باوزير', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                SizedBox(height: 7),
                Text('محلات مدينتك واحتياجاتك اليومية، في مكان واحد.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
              ])),
            ]),
          ),
          const SizedBox(height: 27),
          const Text('ابدأ برقم هاتفك', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 8),
          const Text('سنستخدم رقمك لتجهيز تسجيل الدخول الآمن ومتابعة طلباتك.', style: TextStyle(color: Colors.black54, height: 1.6)),
          const SizedBox(height: 22),
          Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('رقم الهاتف', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              maxLength: 15,
              decoration: InputDecoration(
                counterText: '', hintText: '+967 7XXXXXXXX', prefixIcon: const Icon(Icons.phone_iphone),
                filled: true, fillColor: const Color(0xFFF5F7F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              validator: (value) {
                final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 9 || digits.length > 15) return 'أدخل رقم هاتف صحيحًا مع مفتاح الدولة';
                return null;
              },
            ),
            const SizedBox(height: 14),
            SizedBox(height: 54, child: FilledButton.icon(
              onPressed: _busy ? null : _continue,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('المتابعة برقم الهاتف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(backgroundColor: brand, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            )),
          ])),
          const SizedBox(height: 17),
          const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline, color: brand, size: 18), SizedBox(width: 8),
            Expanded(child: Text('نحافظ على خصوصية بياناتك. لن يتم إرسال رمز تحقق حتى يتم ربط خدمة التسجيل الرسمية.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5))),
          ]),
          const Spacer(),
          if (_canSkipLogin) ...[
            const SizedBox(height: 20),
            OutlinedButton(onPressed: _skipDemo, style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48), foregroundColor: brand,
              side: const BorderSide(color: Color(0xFFB7DCCB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('تخطي مؤقتًا — للمعاينة فقط')),
            const SizedBox(height: 8),
            const Text('وضع تجريبي: لا تستخدم بيانات حقيقية للحساب.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black45)),
          ],
          const SizedBox(height: 16),
          const Center(child: Text('غيل باوزير • حضرموت', style: TextStyle(color: Colors.black45, fontSize: 12))),
        ]),
      ),
    ))),
  );
}

class Shop {
  final String name;
  final String type;
  final String eta;
  final double delivery;
  final IconData icon;
  final bool open;
  final String imageUrl;

  const Shop(this.name, this.type, this.eta, this.delivery, this.icon, this.imageUrl,
      {this.open = true});
}

const shops = <Shop>[
  Shop('مطاعم ووجبات', 'مطاعم', '25–40 دقيقة', 500, Icons.restaurant, 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=700&q=75'),
  Shop('بقالة الحي', 'بقالة', '20–35 دقيقة', 400, Icons.shopping_basket, 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=700&q=75'),
  Shop('صيدلية غيل', 'صيدلية', '25–45 دقيقة', 500, Icons.local_pharmacy, 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=700&q=75'),
  Shop('حلويات ومخبوزات', 'حلويات', '20–35 دقيقة', 400, Icons.cake, 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=700&q=75'),
  Shop('خضار وفواكه', 'خضار وفواكه', '20–30 دقيقة', 400, Icons.eco, 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=700&q=75'),
  Shop('مياه ومشروبات', 'مشروبات', '15–30 دقيقة', 300, Icons.local_drink, 'https://images.unsplash.com/photo-1532634896-26909d0d4b48?w=700&q=75'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String category = 'الكل';
  String query = '';
  final List<CartItem> cart = [];
  Shop? cartShop;

  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeBody(),
      _ordersBody(),
      _accountBody(),
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('غيل باوزير توصيل',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              SizedBox(height: 2),
              Text('📍 غيل باوزير، حضرموت',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'سلة الطلبات',
              onPressed: _openCart,
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ],
        ),
        body: pages[tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'طلباتي'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }

  Widget _homeBody() {
    final filtered = shops.where((s) {
      final matchesCategory = category == 'الكل' || s.type == category;
      final matchesQuery = s.name.contains(query) || s.type.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          height: 208,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [Color(0xFF075B43), Color(0xFF0C9B72)]),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: HybridImage(
                'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=1200&q=75',
                fit: BoxFit.cover, fallbackAsset: 'assets/images/hero_delivery.png',
              ),
            ),
            Positioned.fill(child: Container(color: const Color(0xCC075B43))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)),
                  child: const Text('خدمة محلية لأهل غيل باوزير', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                const Spacer(),
                const Text('كل احتياجاتك،\nتوصلك لباب البيت',
                  style: TextStyle(color: Colors.white, fontSize: 25, height: 1.25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Row(children: [
                  Icon(Icons.bolt, color: Color(0xFFFFD166), size: 18), SizedBox(width: 5),
                  Text('اطلب من محلات مدينتك بسهولة', style: TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ]),
            ),
            const Positioned(left: 14, top: 14, child: Icon(Icons.delivery_dining, color: Colors.white70, size: 38)),
          ]),
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (v) => setState(() => query = v.trim()),
          decoration: InputDecoration(
            hintText: 'ابحث عن محل أو نوع متجر...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 18),
        const Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SizedBox(
          height: 43,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['الكل', 'مطاعم', 'بقالة', 'صيدلية', 'حلويات', 'خضار وفواكه', 'مشروبات']
                .map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => setState(() => category = c),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('محلات مقترحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('${filtered.length} محلات', style: const TextStyle(color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('لا توجد نتائج. جرّب كلمة بحث أخرى.')),
          )
        else
          ...filtered.map(_shopCard),
        const SizedBox(height: 10),
        const Text(
          'ملاحظة: هذه نسخة أولية ببيانات تجريبية. ربط المحلات الحقيقية واستقبال الطلبات يحتاج إعداد قاعدة بيانات وخدمات الخادم.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  String _shopFallbackAsset(Shop shop) {
    if (shop.type == 'مطاعم') return 'assets/images/fallback_food.png';
    if (shop.type == 'بقالة') return 'assets/images/fallback_grocery.png';
    if (shop.type == 'صيدلية') return 'assets/images/fallback_pharmacy.png';
    if (shop.type == 'حلويات') return 'assets/images/fallback_bakery.png';
    if (shop.type == 'خضار وفواكه') return 'assets/images/fallback_produce.png';
    if (shop.type == 'مشروبات') return 'assets/images/fallback_drinks.png';
    return 'assets/images/fallback_food.png';
  }

  Widget _shopCard(Shop shop) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 82, height: 82,
                child: HybridImage(
                  shop.imageUrl, fit: BoxFit.cover,
                  fallbackAsset: _shopFallbackAsset(shop),
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE2F4EC),
                    child: Icon(shop.icon, color: brand, size: 31),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${shop.eta}  •  توصيل ${shop.delivery.toStringAsFixed(0)} ريال',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.access_time, size: 14, color: brand),
                    const SizedBox(width: 4),
                    Text('متاح للطلب التجريبي', style: TextStyle(fontSize: 11, color: shop.open ? brand : Colors.red)),
                  ]),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showShopInfo(shop),
              icon: const Icon(Icons.arrow_forward_ios, size: 17),
            ),
          ],
        ),
      ),
    );
  }

  void _showShopInfo(Shop shop) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shop.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('الوقت المتوقع: ${shop.eta}'),
            Text('رسوم التوصيل التجريبية: ${shop.delivery.toStringAsFixed(0)} ريال يمني'),
            const SizedBox(height: 14),
            const Text('منتجات وأسعار تجريبية للمعاينة. الأسعار قابلة للتعديل قبل الإطلاق.'),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _openProducts(shop);
              },
              icon: const Icon(Icons.storefront),
              label: const Text('عرض المنتجات'),
            )),
          ]),
        ),
      ),
    );
  }

  List<DemoProduct> _productsFor(Shop shop) {
    switch (shop.type) {
      case 'مطاعم':
        return const [DemoProduct('وجبة دجاج', 1800, Icons.dinner_dining), DemoProduct('برجر لحم', 1200, Icons.lunch_dining), DemoProduct('بيتزا صغيرة', 1500, Icons.local_pizza), DemoProduct('بطاطس مقلية', 500, Icons.fastfood), DemoProduct('ماء صغير', 150, Icons.water_drop)];
      case 'بقالة':
        return const [DemoProduct('أرز 1 كجم', 900, Icons.rice_bowl), DemoProduct('سكر 1 كجم', 700, Icons.inventory_2), DemoProduct('حليب', 500, Icons.local_drink), DemoProduct('بيض (طبق صغير)', 1800, Icons.egg), DemoProduct('زيت طبخ', 1400, Icons.oil_barrel)];
      case 'صيدلية':
        return const [DemoProduct('كمامات (علبة)', 1000, Icons.masks), DemoProduct('معقم يدين', 800, Icons.sanitizer), DemoProduct('فيتامينات', 2500, Icons.medication), DemoProduct('شاش طبي', 400, Icons.healing)];
      case 'حلويات':
        return const [DemoProduct('كيك قطعة', 500, Icons.cake), DemoProduct('دونات', 400, Icons.bakery_dining), DemoProduct('بسكويت', 300, Icons.cookie), DemoProduct('معمول (علبة)', 1200, Icons.breakfast_dining)];
      case 'خضار وفواكه':
        return const [DemoProduct('طماطم 1 كجم', 500, Icons.eco), DemoProduct('بطاطس 1 كجم', 600, Icons.eco), DemoProduct('موز 1 كجم', 900, Icons.eco), DemoProduct('ليمون 1 كجم', 700, Icons.eco)];
      default:
        return const [DemoProduct('مياه (كرتون)', 1200, Icons.water_drop), DemoProduct('عصير', 300, Icons.local_drink), DemoProduct('مشروب غازي', 350, Icons.local_drink), DemoProduct('مياه صغيرة', 150, Icons.water_drop)];
    }
  }

  void _openProducts(Shop shop) {
    final products = _productsFor(shop);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(builder: (context, refresh) => SizedBox(
          height: MediaQuery.of(context).size.height * .78,
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 12), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shop.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                Text('رسوم التوصيل ${shop.delivery.toStringAsFixed(0)} ريال • ${shop.eta}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ])),
              IconButton(onPressed: () { Navigator.pop(sheetContext); _openCart(); }, icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_bag_outlined))),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final product = products[index];
                final inCart = cart.where((item) => item.name == product.name && item.shopName == shop.name).fold<int>(0, (n, item) => n + item.quantity);
                return Card(child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFFE2F4EC), child: Icon(product.icon, color: brand)),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${product.price.toStringAsFixed(0)} ريال يمني${inCart > 0 ? ' • في السلة: $inCart' : ''}'),
                  trailing: IconButton.filled(onPressed: () => _addProduct(shop, product, refresh), icon: const Icon(Icons.add_shopping_cart)),
                ));
              },
            )),
            Padding(padding: const EdgeInsets.all(14), child: SizedBox(width: double.infinity, child: FilledButton(
              onPressed: cart.isEmpty ? null : () { Navigator.pop(sheetContext); _openCart(); },
              child: Text('عرض السلة ($cartCount)'),
            ))),
          ]),
        )),
      ),
    );
  }

  void _addProduct(Shop shop, DemoProduct product, void Function(void Function()) refresh) {
    if (cartShop != null && cartShop!.name != shop.name && cart.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
          title: const Text('السلة من محل آخر'),
          content: Text('السلة الحالية من ${cartShop!.name}. هل تريد إفراغها والبدء من ${shop.name}؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
            FilledButton(onPressed: () {
              setState(() { cart.clear(); cartShop = shop; cart.add(CartItem(product.name, product.price, shopName: shop.name)); });
              Navigator.pop(dialogContext);
              refresh(() {});
            }, child: const Text('إفراغ والبدء')),
          ],
        )),
      );
      return;
    }
    setState(() {
      cartShop = shop;
      CartItem? existing;
      for (final item in cart) { if (item.name == product.name && item.shopName == shop.name) { existing = item; break; } }
      if (existing != null) { existing.quantity++; }
      else { cart.add(CartItem(product.name, product.price, shopName: shop.name)); }
    });
    refresh(() {});
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('أُضيف ${product.name} إلى السلة'), duration: const Duration(milliseconds: 900)));
  }

  Widget _ordersBody() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 68, color: brand),
            SizedBox(height: 14),
            Text('طلباتك ستظهر هنا', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('بعد ربط قاعدة البيانات، ستتمكن من متابعة قبول الطلب وتجهيزه وخروجه للتوصيل.'),
            SizedBox(height: 8),
            Text('حالة هذه النسخة: تجريبية', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _accountBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFFE2F4EC), child: Icon(Icons.person, color: brand)),
            title: Text('حساب العميل', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('تسجيل الدخول سيُضاف في مرحلة ربط الخادم'),
          ),
        ),
        const SizedBox(height: 10),
        const Text('أنواع الحسابات في النظام النهائي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _roleTile(Icons.storefront, 'صاحب محل', 'إدارة المنتجات واستقبال الطلبات'),
        _roleTile(Icons.delivery_dining, 'مندوب توصيل', 'استلام الطلبات وتحديث حالة التوصيل'),
        _roleTile(Icons.admin_panel_settings, 'مدير النظام', 'إدارة المحلات والعمولات ورسوم التوصيل'),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('نموذج الربح المختار: عمولة من المحلات + رسوم توصيل على العميل. يجب تحديد النسب والأسعار قبل الإطلاق.'),
          ),
        ),
      ],
    );
  }

  Widget _roleTile(IconData icon, String title, String subtitle) => Card(
        child: ListTile(leading: Icon(icon, color: brand), title: Text(title), subtitle: Text(subtitle)),
      );

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: StatefulBuilder(builder: (context, refresh) {
            final subtotal = cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
            final delivery = cart.isEmpty ? 0.0 : (cartShop?.delivery ?? 0.0);
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('سلة الطلبات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (cartShop != null && cart.isNotEmpty) Text('المحل: ${cartShop!.name}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              if (cart.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('السلة فارغة حاليًا')))
              else
                ConstrainedBox(constraints: const BoxConstraints(maxHeight: 320), child: ListView(shrinkWrap: true, children: cart.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle: Text('${item.price.toStringAsFixed(0)} ريال × ${item.quantity}'),
                  leading: IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () {
                    setState(() { if (item.quantity > 1) { item.quantity--; } else { cart.remove(item); if (cart.isEmpty) cartShop = null; } });
                    refresh(() {});
                  }),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.add_circle_outline, color: brand), onPressed: () { setState(() => item.quantity++); refresh(() {}); }),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { setState(() { cart.remove(item); if (cart.isEmpty) cartShop = null; }); refresh(() {}); }),
                  ]),
                )).toList())),
              const Divider(),
              _moneyRow('قيمة المنتجات', subtotal),
              _moneyRow('رسوم التوصيل', delivery),
              const Divider(),
              _moneyRow('الإجمالي', subtotal + delivery, bold: true),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: cart.isEmpty ? null : () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('السلة تجريبية فقط. إرسال الطلب الحقيقي يحتاج ربط قاعدة البيانات وتسجيل الحساب.')));
                },
                child: const Text('متابعة الطلب (تجريبي)'),
              )),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _moneyRow(String label, double amount, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text('${amount.toStringAsFixed(0)} ريال يمني', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: bold ? brand : ink)),
    ]),
  );

}

class DemoProduct {
  final String name;
  final double price;
  final IconData icon;
  const DemoProduct(this.name, this.price, this.icon);
}

class CartItem {
  final String name;
  final double price;
  final String shopName;
  int quantity;
  CartItem(this.name, this.price, {required this.shopName, this.quantity = 1});
}
