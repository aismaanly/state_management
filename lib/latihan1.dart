import 'package:flutter/material.dart'; // Impor library flutter untuk mengakses framework UI Flutter
import 'package:http/http.dart' as http; // Impor library http untuk melakukan permintaan HTTP
import 'dart:convert'; // Impor library dart:convert untuk mengonversi data
import 'package:url_launcher/url_launcher.dart'; // Impor library url_launcher untuk membuka URL eksternal
import 'package:flutter_bloc/flutter_bloc.dart'; // Impor library flutter_bloc untuk menggunakan Bloc dalam manajemen state

// Fungsi main() yang merupakan entry point dari aplikasi
void main() {
  runApp(
    BlocProvider( // Widget BlocProvider menyediakan instance dari WebsiteCubit ke dalam widget tree
      create: (context) => WebsiteCubit(), // Membuat instance dari WebsiteCubit dan memberikannya kepada widget tree menggunakan BlocProvider
      child: MyApp(), // Memulai aplikasi dengan widget MyApp sebagai root
    ),
  );
}

// Deklarasi list countries yang berisi daftar negara untuk dropdown
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
  String nama; // Variabel untuk menyimpan nama universitas
  String website; // Variabel untuk menyimpan URL situs resmi universitas
  WebsiteUniv({required this.nama, required this.website}); // Konstruktor untuk inisialisasi objek WebsiteUniv
}

// Deklarasi kelas Website untuk merepresentasikan kumpulan data universitas
class Website {
  List<WebsiteUniv> ListPop; // List untuk menyimpan data universitas

  Website({required this.ListPop}); // Konstruktor untuk inisialisasi objek Website dengan data ListPop

  // Factory method untuk membuat instance dari Website dari data JSON
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

// Deklarasi kelas WebsiteCubit yang merupakan turunan dari Cubit dengan tipe state Website
class WebsiteCubit extends Cubit<Website> {
  WebsiteCubit() : super(Website(ListPop: [])); // Konstruktor untuk inisialisasi WebsiteCubit dengan state awal kosong

  // Method untuk mengambil daftar situs web universitas berdasarkan negara
  void fetchWebsites(String country) async {
    if (country == 'Pilih Negara') { // Jika negara yang dipilih adalah "Pilih Negara"
      emit(Website(ListPop: [])); // Emit state kosong
    } else {
      String url = "http://universities.hipolabs.com/search?country=$country"; // URL untuk mengambil data universitas berdasarkan negara
      final response = await http.get(Uri.parse(url)); // Mengirimkan permintaan HTTP untuk mendapatkan data universitas
      if (response.statusCode == 200) { // Jika permintaan berhasil
        emit(Website.fromJson(jsonDecode(response.body))); // Emit state dengan data universitas yang diperoleh dari JSON response
      } else {
        throw Exception('Failed to load websites'); // Jika permintaan gagal, lempar exception
      }
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Universitas dan Situs Resminya'), // Judul AppBar
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButtonFormField<String>(
                value: countries[0], // Nilai default dropdown
                items: countries.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country), // Menampilkan opsi negara pada dropdown
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    context.read<WebsiteCubit>().fetchWebsites(newValue); // Mengambil daftar situs web universitas saat negara dipilih
                  }
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<WebsiteCubit, Website>(
                builder: (context, state) {
                  if (state.ListPop.isEmpty) { // Jika daftar universitas kosong
                    return Center(
                      child: Text('Silahkan Pilih Negara Terlebih Dahulu'), // Menampilkan pesan untuk memilih negara
                    );
                  } else {
                    return ListView.builder( // Menampilkan daftar universitas
                      itemCount: state.ListPop.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _launchURL(state.ListPop[index].website); // Buka situs resmi universitas ketika di-tap
                          },
                          child: Container(
                            decoration: BoxDecoration(border: Border.all()),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(state.ListPop[index].nama), // Menampilkan nama universitas
                                Text(
                                  state.ListPop[index].website, // Menampilkan URL situs resmi universitas
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline, // Tampilan gaya teks agar terlihat seperti tautan
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membuka URL
  void _launchURL(String url) async { 
    if (await canLaunch(url)) {
      await launch(url); // Membuka URL
    } else {
      throw 'Could not launch $url'; // Jika gagal membuka URL, muncul exception dengan pesan tertentu
    }
  }
}
