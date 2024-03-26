import 'dart:convert';

import 'gbk_maps.dart';

GbkCodec gbk = GbkCodec();

Map<int, String> _gbkCodeToChar = {};
Map<String, int> _charToGbkCode = {};

class GbkCodec extends Encoding {
  @override
  Converter<List<int>, String> get decoder => const GbkDecoder();

  @override
  Converter<String, List<int>> get encoder => const GbkEncoder();

  @override
  String get name => 'gbk';

  GbkCodec() {
    //initialize gbk code maps
    _charToGbkCode = json_char_to_gbk;
    json_gbk_to_char.forEach((sInt, sChar) {
      _gbkCodeToChar[int.parse(sInt, radix: 16)] = sChar;
    });
  }
}

class GbkEncoder extends Converter<String, List<int>> {
  const GbkEncoder();

  @override
  List<int> convert(String input) {
    return gbkEncode(input);
  }
}

List<int> gbkEncode(String input) {
  var ret = <int>[];
  input.codeUnits.forEach((charCode) {
    var char = String.fromCharCode(charCode);
    var gbkCode = _charToGbkCode[char];
    if (gbkCode != null) {
      ret.add(gbkCode);
    } else
      ret.add(charCode);
  });
  return ret;
}

class GbkDecoder extends Converter<List<int>, String> {
  const GbkDecoder();

  @override
  String convert(List<int> input) {
    return gbkDecode(input);
  }
}

String gbkDecode(List<int> input) {
  var ret = '';
  /*
  List<int> combined =  List<int>();
  int id= 0;
  while(id<input.length) {
      int charCode = input[id];
      id ++;
      if (charCode < 0x80 || charCode > 0xffff || id == input.length) {
        combined.add(charCode);
      } else {
        charCode = (charCode << 8) + input[id];
        id ++;
        combined.add(charCode);
      }
  }
  */
  input.forEach((charCode) {
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
