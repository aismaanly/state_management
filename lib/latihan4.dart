import 'package:flutter/material.dart'; // Impor library flutter untuk mengakses framework UI Flutter
import 'package:http/http.dart' as http; // Impor library http untuk melakukan permintaan HTTP
import 'dart:convert'; // Impor library dart:convert untuk mengonversi data
import 'package:url_launcher/url_launcher.dart'; // Impor library url_launcher untuk membuka URL eksternal
import 'package:provider/provider.dart'; // Impor library provider untuk menggunakan ChangeNotifierProvider

// Fungsi main() yang merupakan entry point dari aplikasi.
void main() {
  runApp(
    ChangeNotifierProvider( // Widget ChangeNotifierProvider yang memberikan instance dari WebsiteProvider ke dalam widget tree
      create: (context) => WebsiteProvider(), // Membuat instance dari WebsiteProvider dan memberikannya kepada widget tree menggunakan ChangeNotifierProvider
      child: MyApp(), // Memulai aplikasi dengan widget MyApp sebagai root
    ),
  );
}

// Deklarasi list negara yang berisi daftar negara pada universitas di ASEAN untuk dropdown
  final List<String> countries = [
    'Pilih Negara',
    'Brunei Darussalam',
    'Cambodia',
    'Indonesia',
    'Lao People\'s Democratic Republic',
    'Malaysia',
    'Myanmar',
    'Philippines',
    'Singapore',
    'Thailand',
    'Vietnam'
  ];

// Deklarasi kelas WebsiteUniv untuk merepresentasikan sebuah universitas
class WebsiteUniv {
  String nama; 
  String website;
  WebsiteUniv({required this.nama, required this.website});
}

// Deklarasi kelas Website untuk merepresentasikan kumpulan data universitas
class Website {
  List<WebsiteUniv> ListPop; 
  Website({required this.ListPop});

  factory Website.fromJson(List<dynamic> json) {
    List<WebsiteUniv> list = [];
    for (var val in json) {
      var namaUniv = val["name"];
      var websiteUniv = val["web_pages"][0];
      list.add(WebsiteUniv(nama: namaUniv, website: websiteUniv));
    }
    return Website(ListPop: list);
  }
}

// Deklarasi kelas WebsiteProvider yang merupakan turunan dari ChangeNotifier
class WebsiteProvider with ChangeNotifier { 
  String selectedCountry = 'Pilih Negara'; // Memberikan nilai awal untuk selectedCountry
  Future<Website>? futureWebsite; // Deklarasi futureWebsite sebagai Future yang berisi data dari website

  void changeCountry(String country) { // Method untuk mengubah negara dan memperbarui data universitas
    selectedCountry = country; // Mengubah negara yang dipilih
    futureWebsite = fetchData(); // Memperbarui data universitas
    notifyListeners(); // Memberi tahu listener bahwa state telah berubah
  }

  // Method untuk mengambil data universitas dari API
  Future<Website> fetchData() async {
    if (selectedCountry == 'Pilih Negara') return Website(ListPop: []); // Jika negara yang dipilih adalah "Pilih Negara", kembalikan Website kosong
    String url = "http://universities.hipolabs.com/search?country=$selectedCountry"; // URL API untuk mendapatkan data universitas berdasarkan negara
    final response = await http.get(Uri.parse(url)); // Mengirim permintaan HTTP GET untuk mendapatkan data universitas
    if (response.statusCode == 200) {
      return Website.fromJson(jsonDecode(response.body)); // Jika permintaan berhasil, kembalikan data universitas yang di-decode dari JSON response
    } else {
      throw Exception('Gagal load'); // Jika permintaan gagal, lemparkan exception
    }
  }
}

// Deklarasi kelas MyApp yang merupakan turunan dari StatelessWidget
class MyApp extends StatelessWidget { 
  @override
  // Method build pada kelas MyApp untuk membangun tata letak aplikasi
  Widget build(BuildContext context) { 
    // Widget MaterialApp yang menyediakan beberapa konfigurasi aplikasi
    return MaterialApp(
      title: 'Universitas di ASEAN', // Judul aplikasi
      home: Scaffold( // Widget Scaffold yang menyediakan kerangka aplikasi dengan AppBar dan body
        appBar: AppBar(
          title: const Text('Universitas dan Situs Resminya'), // Widget AppBar untuk menampilkan judul aplikasi
        ),
        body: Column( // Widget Column untuk menyusun widget secara vertikal
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>( // Widget DropdownButtonFormField untuk menampilkan dropdown negara
                value: Provider.of<WebsiteProvider>(context).selectedCountry, // Menentukan nilai dropdown berdasarkan negara yang dipilih
                items: countries.map((String country) { // Menampilkan opsi negara pada dropdown
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) { // Mengubah negara yang dipilih saat nilai dropdown berubah
                  Provider.of<WebsiteProvider>(context, listen: false).changeCountry(newValue!); // Memanggil Method changeCountry dari WebsiteProvider untuk memperbarui negara yang dipilih
                },
              ),
            ),
            Expanded( // Widget Expanded untuk mengisi ruang yang tersisa dalam kolom
              child: Consumer<WebsiteProvider>( // Widget Consumer untuk mendengarkan perubahan pada WebsiteProvider
                builder: (context, websiteProvider, child) { // Method build yang akan dipanggil ketika WebsiteProvider berubah
                  return FutureBuilder<Website>( // Widget FutureBuilder untuk menampilkan data universitas yang akan datang
                    future: websiteProvider.futureWebsite, // Menentukan Future yang akan di-build
                    builder: (context, snapshot) { // Method build yang akan dipanggil ketika future selesai
                      if (snapshot.connectionState == ConnectionState.waiting) { // Jika future masih dalam proses
                        return Center(child: CircularProgressIndicator()); // Menampilkan indikator loading
                      }
                      if (snapshot.hasError) { // Jika terjadi error pada future
                        return Center(child: Text('${snapshot.error}')); // Menampilkan pesan error
                      }
                      if (snapshot.hasData && snapshot.data!.ListPop.isNotEmpty) { // Jika data berhasil dimuat dan tidak kosong
                        return ListView.builder( // Menampilkan daftar universitas
                          itemCount: snapshot.data!.ListPop.length,
                          itemBuilder: (context, index) {
                            return GestureDetector( // Widget GestureDetector untuk menangani ketukan pada daftar universitas
                              onTap: () { // Ketika daftar universitas di-tap
                                _launchURL(snapshot.data!.ListPop[index].website); // Buka situs resmi universitas
                              },
                              child: Container(
                                decoration: BoxDecoration(border: Border.all()),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(snapshot.data!.ListPop[index].nama), // Menampilkan nama universitas
                                    Text(
                                      snapshot.data!.ListPop[index].website, // Menampilkan URL situs resmi universitas
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else { // Jika data kosong atau belum di-fetch
                        return Center(
                          child: Text('Silahkan Pilih Negara Terlebih Dahulu'), // Menampilkan pesan untuk memilih negara
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuka URL situs resmi universitas
  void _launchURL(String url) async { 
    if (await canLaunch(url)) {
      await launch(url); // Membuka URL
    } else {
      throw 'Could not launch $url'; // Jika gagal membuka URL, muncul exception dengan pesan tertentu
    }
  }
}
