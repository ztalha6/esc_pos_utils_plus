import 'dart:async';

abstract class PlatformServiceInterface {
  FutureOr<bool> printDirectWindows(
      {required String printerName, required List<int> bytes});

  FutureOr<bool> printSocket(
      {required String host, required int port, required List<int> bytes});

  FutureOr<bool> printSerialBluetooth(
      {required String serialNumber, required List<int> bytes});

  FutureOr<bool> printUSB(
      {required String serialNumber, required List<int> bytes});
}
