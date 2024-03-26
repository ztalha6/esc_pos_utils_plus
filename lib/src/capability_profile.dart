import 'dart:convert' show json;
import 'package:flutter/services.dart' show rootBundle;

List<Map> printProfiles = [];
Map printCapabilities = {};

class CodePage {
  CodePage(this.id, this.name);
  int id;
  String name;
}

class CapabilityProfile {
  CapabilityProfile._internal(this.name, this.codePages);

  /// [ensureProfileLoaded]
  /// this method will cache the profile json into data which will
  /// speed up the next loop and searching profile
  static Future ensureProfileLoaded({String? path}) async {
    /// check where this global capabilities is empty then load capabilities.json
    /// else do nothing
    if (printCapabilities.isEmpty == true) {
      final content = await rootBundle.loadString(path ??
          'packages/esc_pos_utils_plus_forked/resources/capabilities.json');
      var _capabilities = json.decode(content);
      printCapabilities = Map.from(_capabilities);

      (_capabilities['profiles'] as Map).forEach((k, v) {
        printProfiles.add({
          'key': k,
          'vendor': v['vendor'] is String ? v['vendor'] : '',
          'name': v['name'] is String ? v['name'] : '',
          'description': v['description'] is String ? v['description'] : '',
        });
      });

      /// assert that the capabilities will be not empty
      assert(printCapabilities.isNotEmpty);
    } else {
      print("capabilities.length is already loaded");
    }
  }

  /// Public factory
  static Future<CapabilityProfile> load({String name = 'default'}) async {
    ///
    await ensureProfileLoaded();

    var profile = printCapabilities['profiles'][name];

    if (profile == null) {
      throw Exception("The CapabilityProfile '$name' does not exist");
    }

    List<CodePage> list = [];
    (profile['codePages'] as Map).forEach((k, v) {
      list.add(CodePage(int.parse(k), v));
    });

    // Call the private constructor
    return CapabilityProfile._internal(name, list);
  }

  String name;
  List<CodePage> codePages;

  int getCodePageId(String? codePage) {
    if (codePages.isEmpty) {
      throw Exception("The CapabilityProfile isn't initialized");
    }

    return codePages
        .firstWhere((cp) => cp.name == codePage,
            // ignore: unnecessary_cast
            orElse: (() => throw Exception(
                    "Code Page '$codePage' isn't defined for this profile"))
                as CodePage Function()?)
        .id;
  }

  static Future<List<dynamic>> getAvailableProfiles() async {
    /// ensure the capabilities is not empty
    await ensureProfileLoaded();

    var _profiles = printCapabilities['profiles'] as Map;

    List<dynamic> res = [];

    _profiles.forEach((k, v) {
      res.add({
        'key': k,
        'vendor': v['vendor'] is String ? v['vendor'] : '',
        'name': v['name'] is String ? v['name'] : '',
        'description': v['description'] is String ? v['description'] : '',
      });
    });

    return res;
  }
}
