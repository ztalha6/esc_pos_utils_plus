import 'package:example/platform_service/platform_service.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

enum PrintMode { USB, NETWORK }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String printerName = "RONGTA 80mm Series Printer(1)";
  late String printerAddress = "192.168.110.15";

  late TextEditingController printNameCtrl =
      TextEditingController(text: printerName);
  late TextEditingController printAddressCtrl =
      TextEditingController(text: printerAddress);

  late PrintMode mode = PrintMode.USB;

  @override
  void dispose() {
    printNameCtrl.dispose();
    printAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("generator for esc printer"),
        actions: [
          DropdownButton(
              value: mode,
              items: PrintMode.values
                  .map((e) => DropdownMenuItem(
                        child: Text(e.name),
                        value: e,
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                    mode = v!;
                  }))
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (mode == PrintMode.USB) ...[
              TextFormField(
                controller: printNameCtrl,
                onChanged: (v) => setState(() {
                  printerName = v;
                }),
                decoration: InputDecoration(label: Text("Printer Name")),
              )
            ],
            if (mode == PrintMode.NETWORK) ...[
              TextFormField(
                controller: printAddressCtrl,
                onChanged: (v) => setState(() {
                  printerAddress = v;
                }),
                decoration: InputDecoration(label: Text("Printer Address")),
              )
            ],
            Expanded(
              child: ListView(
                children: [
                  ListTile(onTap: generate, title: Text("generate")),
                  ListTile(onTap: printText, title: Text("print text")),
                  ListTile(onTap: printColumns, title: Text("print columns")),
                  ListTile(onTap: printImage, title: Text("print image")),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  generate() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: PosStyles(codeTable: 'CP1252'));
    bytes += generator.text('Special 2: blåbærgrød',
        styles: PosStyles(codeTable: 'CP1252'));

    bytes += generator.text('Bold text', styles: PosStyles(bold: true));
    bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: PosStyles(underline: true), linesAfter: 1);
    bytes +=
        generator.text('Align left', styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.text('Text size 200%',
        styles: PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    // Print image:
    final ByteData data = await rootBundle.load('assets/images/logo.png');
    final Uint8List imgBytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(imgBytes)!;

    /// bytes += generator.image(image);
    // Print image using an alternative (obsolette) command
    bytes += generator.imageRaster(image);

    // Print barcode
    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    // Print mixed (chinese + latin) text. Only for printers supporting Kanji mode
    generator.text(
      "hello ! 中文字 # world @ éphémère &",
      styles: PosStyles(
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
      containsChinese: true,
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
  }

  printText() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: PosStyles(codeTable: 'CP1252'));
    bytes += generator.text('Special 2: blåbærgrød',
        styles: PosStyles(codeTable: 'CP1252'));

    bytes += generator.text('Bold text', styles: PosStyles(bold: true));
    bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: PosStyles(underline: true), linesAfter: 1);
    bytes +=
        generator.text('Align left', styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.feed(2);
    bytes += generator.cut();

    ///
    debugPrint("start print ====================");
    final service = PlatformService();
    try {
      if (mode == PrintMode.NETWORK) {
        service.printSocket(host: printerAddress, port: 9100, bytes: bytes);
      } else {
        service.printDirectWindows(printerName: printerName, bytes: bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  printColumns() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
    bytes += generator.text('Special 1: àÀ èÈ éÉ ûÛ üÜ çÇ ôÔ',
        styles: PosStyles(codeTable: 'CP1252'));
    bytes += generator.text('Special 2: blåbærgrød',
        styles: PosStyles(codeTable: 'CP1252'));

    bytes += generator.text('Bold text', styles: PosStyles(bold: true));
    bytes += generator.text('Reverse text', styles: PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: PosStyles(underline: true), linesAfter: 1);
    bytes +=
        generator.text('Align left', styles: PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.cut();

    ///
    debugPrint("start print ====================");
    final service = PlatformService();
    try {
      if (mode == PrintMode.NETWORK) {
        service.printSocket(host: printerAddress, port: 9100, bytes: bytes);
      } else {
        service.printDirectWindows(printerName: printerName, bytes: bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  printImage() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Print image:
    final ByteData data = await rootBundle.load('assets/images/logo.png');
    final Uint8List imgBytes = data.buffer.asUint8List();
    final img.Image image = img.decodeImage(imgBytes)!;

    // Print image using an alternative (obsolette) command
    // okay
    var ratio = image.width / image.height;
    bytes += generator.imageRaster(img.copyResize(image,
        width: (297 * 2), height: (image.height * ratio).toInt()));

    bytes += generator.feed(2);
    bytes += generator.cut();

    ///
    debugPrint("start print ====================");
    final service = PlatformService();
    try {
      if (mode == PrintMode.NETWORK) {
        service.printSocket(host: printerAddress, port: 9100, bytes: bytes);
      } else {
        service.printDirectWindows(printerName: printerName, bytes: bytes);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
