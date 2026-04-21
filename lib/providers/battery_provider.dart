import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class BatteryProvider extends ChangeNotifier {
  final Battery _battery = Battery();
  int _level = 0;
  bool _isCharging = false;

  int get level => _level;
  bool get isCharging => _isCharging;

  void initialize() {
    _fetchLevel();
    _battery.onBatteryStateChanged.listen((state) {
      _isCharging =
          state == BatteryState.charging || state == BatteryState.full;
      _fetchLevel();
      notifyListeners();
    });
  }

  Future<void> _fetchLevel() async {
    _level = await _battery.batteryLevel;
    notifyListeners();
  }
}
