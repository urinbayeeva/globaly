import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._checker);
  final InternetConnection _checker;

  @override
  Future<bool> get isConnected => _checker.hasInternetAccess;
}
