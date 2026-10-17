import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// todo.exe PRO: 한 번 결제(비소모성)로 테마·CRT·위젯을 연다.
///
/// App Store Connect / Google Play Console 에 [productId] 로 비소모성 상품을 만들어야 한다.
class ProController extends ChangeNotifier {
  ProController({InAppPurchase? iap}) : _iapOverride = iap;

  static const productId = 'todo_exe_pro';
  static const _prefsKey = 'todo_exe_pro_v1';

  final InAppPurchase? _iapOverride;
  InAppPurchase get _iap => _iapOverride ?? InAppPurchase.instance;

  SharedPreferences? _prefs;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Timer? _restoreTimeout;

  bool _unlocked = false;
  bool _devOverride = false;

  /// 스토어에 연결됐는지.
  bool available = false;

  /// 스토어에서 받아온 상품 (가격 표시용). 등록 전이면 null.
  ProductDetails? product;

  /// 결제/복원 진행 중.
  bool busy = false;

  /// 화면 아래에 보여줄 최근 메시지.
  String? message;
  bool messageIsError = false;

  bool get isPro => _unlocked || _devOverride;

  /// 가격 문자열. 상품을 못 불러왔으면 null.
  String? get price => product?.price;

  static bool get _platformSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _unlocked = _prefs!.getBool(_prefsKey) ?? false;
    notifyListeners();
    if (!_platformSupported) return;
    // 스토어 연결은 느릴 수 있으니 앱 시작을 막지 않는다.
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => _setMessage(tr('p.stream', {'e': e}), error: true),
      );
      available = await _iap.isAvailable();
      if (available) await loadProduct();
    } catch (e) {
      debugPrint('todo.exe pro: 초기화 실패 ($e)');
      available = false;
    }
    notifyListeners();
  }

  Future<void> loadProduct() async {
    try {
      final res = await _iap.queryProductDetails({productId});
      product = res.productDetails.isEmpty ? null : res.productDetails.first;
      if (product == null) {
        debugPrint('todo.exe pro: 상품을 찾지 못함 ${res.notFoundIDs} ${res.error}');
      }
    } catch (e) {
      debugPrint('todo.exe pro: 상품 조회 실패 ($e)');
    }
    notifyListeners();
  }

  Future<void> buy() async {
    if (isPro || busy) return;
    if (!available) {
      _setMessage(tr('p.nostore'), error: true);
      return;
    }
    if (product == null) {
      await loadProduct();
      if (product == null) {
        _setMessage(tr('p.noproduct'), error: true);
        return;
      }
    }
    busy = true;
    _setMessage(tr('p.opening'));
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product!));
    } catch (e) {
      busy = false;
      _setMessage(tr('p.startfail', {'e': e}), error: true);
    }
  }

  Future<void> restore() async {
    if (busy) return;
    if (!available) {
      _setMessage(tr('p.nostore'), error: true);
      return;
    }
    busy = true;
    _setMessage(tr('p.checking'));
    try {
      await _iap.restorePurchases();
    } catch (e) {
      busy = false;
      _setMessage(tr('p.restorefail', {'e': e}), error: true);
      return;
    }
    // 복원할 내역이 없으면 스트림에 아무것도 오지 않는다.
    _restoreTimeout?.cancel();
    _restoreTimeout = Timer(const Duration(seconds: 8), () {
      if (busy && !isPro) {
        busy = false;
        _setMessage(tr('p.norestore'));
      }
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID == productId) {
        switch (p.status) {
          case PurchaseStatus.pending:
            busy = true;
            _setMessage(tr('p.pending'));
          case PurchaseStatus.purchased || PurchaseStatus.restored:
            busy = false;
            await _unlock();
            _setMessage(tr(p.status == PurchaseStatus.restored ? 'p.restored' : 'p.bought'));
          case PurchaseStatus.error:
            busy = false;
            _setMessage(tr('p.failed', {'msg': p.error?.message ?? ''}).trim(), error: true);
          case PurchaseStatus.canceled:
            busy = false;
            _setMessage(tr('p.cancel'));
        }
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          debugPrint('todo.exe pro: completePurchase 실패 ($e)');
        }
      }
    }
  }

  Future<void> _unlock() async {
    _unlocked = true;
    _restoreTimeout?.cancel();
    await _prefs?.setBool(_prefsKey, true);
    notifyListeners();
  }

  /// 디버그 빌드 전용: 결제 없이 PRO 화면·위젯 잠금을 확인할 때 쓴다 (`pro --dev`).
  void debugToggle() {
    if (!kDebugMode) return;
    _devOverride = !_devOverride;
    notifyListeners();
  }

  void _setMessage(String text, {bool error = false}) {
    message = text;
    messageIsError = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _restoreTimeout?.cancel();
    super.dispose();
  }
}
