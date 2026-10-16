import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

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
              child: Image.network(
                'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=1200&q=75',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                child: Image.network(
                  shop.imageUrl, fit: BoxFit.cover,
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
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shop.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('الوقت المتوقع: ${shop.eta}'),
              Text('رسوم التوصيل التجريبية: ${shop.delivery.toStringAsFixed(0)} ريال يمني'),
              const SizedBox(height: 12),
              const Text('هذا قسم تجريبي. عند ربط قاعدة البيانات ستظهر المنتجات الحقيقية وأسعارها.'),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('سنضيف قائمة المنتجات عند إعداد بيانات المحلات.')),
                    );
                  },
                  child: const Text('عرض المنتجات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          child: StatefulBuilder(
            builder: (context, refresh) {
              final total = cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('سلة الطلبات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('السلة فارغة حاليًا')),
                    )
                  else
                    ...cart.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          subtitle: Text('${item.price.toStringAsFixed(0)} ريال × ${item.quantity}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() => cart.remove(item));
                              refresh(() {});
                            },
                          ),
                        )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الإجمالي التجريبي', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${total.toStringAsFixed(0)} ريال يمني', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: cart.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('إرسال الطلب الحقيقي يتطلب إعداد قاعدة البيانات وتسجيل الحساب.')),
                              );
                            },
                      child: const Text('متابعة الطلب (تجريبي)'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class CartItem {
  final String name;
  final double price;
  int quantity;
  CartItem(this.name, this.price, {this.quantity = 1});
}
