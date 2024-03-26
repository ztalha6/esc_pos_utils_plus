import 'dart:convert';

import 'gbk_maps.dart';

GbkBytesCodec gbkBytes = GbkBytesCodec();

Map<int, String> _gbkCodeToChar = {};
Map<String, int> _charToGbkCode = {};

class GbkBytesCodec extends Encoding {
  @override
  Converter<List<int>, String> get decoder => const GbkBytesDecoder();

  @override
  Converter<String, List<int>> get encoder => const GbkBytesEncoder();

  @override
  String get name => 'gbk_bytes';

  GbkBytesCodec() {
    //initialize gbk code maps
    _charToGbkCode = json_char_to_gbk;
    json_gbk_to_char.forEach((sInt, sChar) {
      _gbkCodeToChar[int.parse(sInt, radix: 16)] = sChar;
    });
  }
}

class GbkBytesEncoder extends Converter<String, List<int>> {
  const GbkBytesEncoder();

  @override
  List<int> convert(String input) {
    return gbkBytesEncode(input);
  }
}

List<int> gbkBytesEncode(String input) {
  var ret = <int>[];
  input.codeUnits.forEach((charCode) {
    var char = String.fromCharCode(charCode);
    //print(char);
    var gbkCode = _charToGbkCode[char];
    //print('$char  = ${gbkCode.toRadixString(16)}');
    if (gbkCode != null) {
      //split to two bytes
      var a = (gbkCode >> 8) & 0xff;
      var b = gbkCode & 0xff;
      ret.add(a);
      ret.add(b);
      //print(' ${gbkCode.toRadixString(16)}  -- ${a.toRadixString(16)}  ${b.toRadixString(16)}');
    } else {
      ret.add(charCode);
    }
  });
  return ret;
}

class GbkBytesDecoder extends Converter<List<int>, String> {
  const GbkBytesDecoder();

  @override
  String convert(List<int> input) {
    return gbkBytesDecode(input);
  }
}

String gbkBytesDecode(List<int> input) {
  var ret = '';
  var combined = <int>[];
  var id = 0;
  while (id < input.length) {
    var charCode = input[id];
    id++;
    if (charCode < 0x80 || charCode > 0xff || id == input.length) {
      combined.add(charCode);
    } else {
      charCode = ((charCode) << 8) + (input[id] & 0xff);
      id++;
      combined.add(charCode);
    }
  }
  combined.forEach((charCode) {
    var char = _gbkCodeToChar[charCode];
    if (char != null) {
      ret += char;
    } else {
      ret += String.fromCharCode(charCode);
    }
    //print(ret);
  });
  return ret;
}
