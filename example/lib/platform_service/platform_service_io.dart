// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:ffi';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:io';
import 'dart:typed_data';

import 'platform_service_interface.dart';

extension _IntParsing on List<int> {
  Pointer<Uint8> toUint8() {
    final result = calloc<Uint8>(length);
    final nativeString = result.asTypedList(length);
    nativeString.setAll(0, this);
    return result;
  }
}

class PlatformService extends PlatformServiceInterface {
  @override
  FutureOr<bool> printDirectWindows(
      {required String printerName, required List<int> bytes}) async {
    try {
      /// [win32]
      Pointer<IntPtr>? phPrinter = calloc<HANDLE>();
      Pointer<Utf16> pDocName = 'My Document'.toNativeUtf16();
      Pointer<Utf16> pDataType = 'RAW'.toNativeUtf16();
      Pointer<Uint32>? dwBytesWritten = calloc<DWORD>();
      Pointer<DOC_INFO_1>? docInfo;
      late Pointer<Utf16> szPrinterName;
      late int hPrinter;
      int? dwCount;

      docInfo = calloc<DOC_INFO_1>()
        ..ref.pDocName = pDocName
        ..ref.pOutputFile = nullptr
        ..ref.pDatatype = pDataType;
      szPrinterName = printerName.toNativeUtf16();

      phPrinter = calloc<HANDLE>();
      if (OpenPrinter(szPrinterName, phPrinter, nullptr) == FALSE) {
        debugPrint("can not open");
        return false;
      } else {
        hPrinter = phPrinter.value;
        debugPrint("szPrinterName: $szPrinterName");
      }

      // Inform the spooler the document is beginning.
      final dwJob = StartDocPrinter(hPrinter, 1, docInfo);
      if (dwJob == 0) {
        debugPrint("dwJob == 0");
        ClosePrinter(hPrinter);
        return false;
      }
      // Start a page.
      if (StartPagePrinter(hPrinter) == 0) {
        debugPrint("StartPagePrinter == 0");
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return false;
      }

      // Send the data to the printer.
      final lpData = bytes.toUint8();
      dwCount = bytes.length;
      if (WritePrinter(hPrinter, lpData, dwCount, dwBytesWritten) == 0) {
        debugPrint("WritePrinter == 0");
        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return false;
      }

      // End the page.
      if (EndPagePrinter(hPrinter) == 0) {
        debugPrint("EndPagePrinter == 0");
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
      }

      // Inform the spooler that the document is ending.
      if (EndDocPrinter(hPrinter) == 0) {
        debugPrint("EndDocPrinter == 0");
        ClosePrinter(hPrinter);
      }

      // Check to see if correct number of bytes were written.
      if (dwBytesWritten.value != dwCount) {
        debugPrint("dwBytesWritten.value != dwCount");
      }

      ClosePrinter(hPrinter);

      free(phPrinter);
      free(pDocName);
      free(pDataType);
      free(dwBytesWritten);
      free(docInfo);
      free(szPrinterName);
      return true;
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  @override
  FutureOr<bool> printSerialBluetooth(
      {required String serialNumber, required List<int> bytes}) {
    return false;
  }

  @override
  FutureOr<bool> printSocket(
      {required String host,
      required int port,
      required List<int> bytes}) async {
    final socket =
        await Socket.connect(host, port, timeout: const Duration(seconds: 5));

    final chunked = bytes.splitByLength(250);
    final stream = Stream<List<int>>.fromIterable(chunked);
    try {
      // add chunked stream
      await socket.addStream(stream);

      // then disconnect
      socket.flush();
      socket.close();
      socket.destroy();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  FutureOr<bool> printUSB(
      {required String serialNumber, required List<int> bytes}) {
    return false;
  }
}
