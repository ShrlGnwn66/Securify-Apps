import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:securify/Screen/fullscreenimage.dart';

class DetailPage extends StatelessWidget {
  final dynamic entry;

  final TextStyle customTextStyle = const TextStyle(
      fontSize: 18, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic);

  const DetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F94FC),
        title: const Text(
          "Details",
          style: TextStyle(
              fontSize: 25, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        toolbarHeight: 50,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
              child: GestureDetector(
                onTap: () {
                  if (entry['img'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImagePage(
                          imageBase64: entry['img'],
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 400,
                  height: 300,
                  decoration: BoxDecoration(
                    image: entry['img'] != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(entry['img'])),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/No_image.png'),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text(
                    "Keterangan: ${entry['keterangan'] ?? '-'}",
                    style: customTextStyle,
                  ),
                  const Divider(),
                  Text(
                    "Tanggal: ${entry['Tanggal'] ?? '-'}",
                    style: customTextStyle,
                  ),
                  const Divider(),
                  Text(
                    "Waktu: ${entry['waktu'] ?? '-'}",
                    style: customTextStyle,
                  ),
                  const Divider(),
                  const SizedBox(height: 25),
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (await _checkPermissions(context)) {
                            // ignore: use_build_context_synchronously
                            await _generateAndSavePdf(context, entry);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          "Download",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk save dokumen ke PDF
  Future<void> _generateAndSavePdf(BuildContext context, dynamic entry) async {
    final pdf = pw.Document();

    final pdfTextStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.normal,
      fontStyle: pw.FontStyle.italic,
    );

    final imageProvider = entry['img'] != null
        ? pw.MemoryImage(base64Decode(entry['img']))
        : null;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (imageProvider != null)
                pw.Image(imageProvider, height: 300, fit: pw.BoxFit.cover),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text("Keterangan: ${entry['keterangan'] ?? '-'}",
                  style: pdfTextStyle),
              pw.Divider(),
              pw.Text("Tanggal: ${entry['Tanggal'] ?? '-'}",
                  style: pdfTextStyle),
              pw.Divider(),
              pw.Text("Waktu: ${entry['waktu'] ?? '-'}", style: pdfTextStyle),
              pw.Divider(),
            ],
          );
        },
      ),
    );

    // Generate nama file random
    final random = Random();

    String randomString(int length) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      return String.fromCharCodes(Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    }

    final fileName = '${randomString(6)}.pdf';

    // Save PDF to Downloads folder
    final directory = Directory('/storage/emulated/0/Download');
    final path = "${directory.path}/$fileName";

    // Memastikan folder Download ada
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('PDF berhasil disimpan di folder Download\n$path')),
    );
  }

  // Fungsi untuk cek izin akses direktori handphone
  Future<bool> _checkPermissions(BuildContext context) async {
    if (await Permission.storage.request().isGranted) {
      return true;
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Izin untuk menyimpan file tidak diberikan')),
      );
      return false;
    }
  }
}
