import 'dart:async';

/// Petit bus interne : quand on change d'onglet, certains écrans montés
/// en mémoire (IndexedStack) doivent recharger leurs données.
class RefreshBus {
  static final RefreshBus instance = RefreshBus._();

  RefreshBus._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() => _controller.add(null);
}
