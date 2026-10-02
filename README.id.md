# Wealthy

[English](README.md) · [日本語](README.ja.md) · [简体中文](README.zh-Hans.md) · [हिन्दी](README.hi.md) · [Español](README.es.md) · [العربية](README.ar.md) · [Français](README.fr.md) · [Bahasa Indonesia](README.id.md) · [한국어](README.ko.md) · [Русский](README.ru.md) · [Português](README.pt.md)

Wealthy adalah aplikasi iPhone dan iPad untuk mencatat pengeluaran, pemasukan, dan saldo dompet. Pemindaian struk, ringkasan pengeluaran, dan AI di perangkat membantu Anda meninjau keuangan.

## Fitur

- Mencatat pemasukan dan pengeluaran menurut dompet dan kategori.
- Memindai struk, memeriksa hasil, dan menyimpan gambar asli.
- Melihat transaksi di kalender dan pengeluaran per kategori.
- Menerapkan transaksi bulanan berulang saat aplikasi dibuka.
- Bertanya tentang catatan Anda melalui Apple Foundation Models.
- Membaca tips singkat dengan humor ringan berdasarkan pemasukan, pengeluaran, dan aset yang dicatat.
- Mengekspor dan memulihkan catatan keuangan, dengan gambar struk sebagai pilihan.
- Mencatat aset dan transaksi dalam beberapa mata uang dengan saldo yang terpisah.


## Beberapa mata uang

- Mendukung **155 mata uang ISO 4217 aktif**, berdasarkan daftar SIX yang diterbitkan pada 2026-09-17.
- Setelah memilih bahasa antarmuka pada penggunaan pertama, pilih satu atau beberapa mata uang untuk diaktifkan. Di **Beranda → Pengaturan**, edit mata uang aktif dan pilih mata uang bawaan untuk catatan baru.
- Aset dan riwayat transaksi mempertahankan mata uang yang tersimpan pada tiap catatan. Saldo tetap terpisah dan Analisis dapat beralih di antara mata uang aktif. Tidak ada konversi valuta asing otomatis.
- Jumlah disimpan dalam unit minor ISO: JPY memiliki 0 angka desimal, USD 2, dan KWD 3. Catatan lama tetap menggunakan JPY.
- OCR struk tidak berubah: menargetkan teks bahasa Jepang dan Inggris serta mengekstrak jumlah bulat JPY secara otomatis. Jumlah mata uang asing harus dimasukkan dan ditinjau secara manual.

## Metode pembayaran dan kartu poin

Struk menyarankan dompet sesuai metode pembayaran tercetak; jika tidak tercantum, digunakan Tunai. Konfirmasi simpan mengurangi saldo satu kali. Dompet yang belum ada dibuat dengan saldo nol dan menjadi negatif, misalnya `¥0 → ¥-1,200`. Mengedit atau menghapus catatan juga menyesuaikan saldo. Beberapa metode, penukaran poin, atau beberapa dompet yang cocok perlu ditinjau manual. Ini merupakan aturan atas teks OCR; akurasi metode pembayaran pada foto belum diukur.

Di **Dompet**, edit dompet yang dibuat otomatis untuk menetapkan saldo saat ini, atau daftarkan saldo awal yang ditambahkan ke saldo tercatat. Kartu poin dapat memiliki nama, nomor anggota opsional, saldo poin, dan tanggal kedaluwarsa opsional. Poin dimasukkan manual, terpisah dari aset uang, dan disertakan dalam cadangan keuangan.

Sinkronisasi saldo otomatis dengan bank dan layanan pembayaran **belum diterapkan**. Integrasi awal yang diusulkan adalah SBI Shinsei Bank dan DOCOMO SMTB Net Bank, dahulu SBI Sumishin Net Bank. Izin membuka aplikasi bank saja tidak dapat membaca saldo; diperlukan layanan berbagi akun yang disetujui. Lihat [kajian integrasi](Documentation/FinancialServiceIntegration.md).

## Persyaratan

Diperlukan **iOS atau iPadOS 26.0 atau lebih baru** dan **perangkat yang mendukung Apple Intelligence**. Apple Intelligence harus aktif dan model sistemnya siap sebelum aplikasi dapat digunakan.

| Perangkat | Perangkat keras yang didukung |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, model iPhone 16 dan lebih baru, atau iPhone Air |
| iPad | Model dengan M1 atau lebih baru, atau iPad mini dengan A17 Pro |

Batasan bahasa dan wilayah Apple juga berlaku. Wealthy memeriksa ketersediaan model saat dimulai dan kembali ke latar depan. Lihat [persyaratan terbaru Apple](https://www.apple.com/apple-intelligence/).

## Menggunakan aplikasi

1. Aktifkan Apple Intelligence di **Pengaturan → Apple Intelligence & Siri** dan tunggu model selesai disiapkan.
2. Pilih satu dari **11 bahasa antarmuka** pada popup pertama. Bahasa Inggris adalah bawaan dan pilihan Anda disimpan. Ubah nanti melalui **Beranda → Pengaturan → Pengaturan Bahasa**. Antarmuka Arab menggunakan arah kanan ke kiri.
3. Pilih satu atau beberapa mata uang untuk diaktifkan. Anda dapat mengubah mata uang aktif dan mata uang bawaan untuk catatan baru nanti di **Beranda → Pengaturan**.
4. Tambahkan dompet, lalu catat pemasukan atau pindai struk. Periksa hasil sebelum menyimpan.
5. Tinjau tab Kalender dan Analisis, atau buka asisten AI untuk bertanya tentang catatan Anda.

Bahasa antarmuka mencakup Inggris, Jepang, Mandarin sederhana, Hindi, Spanyol, Arab, Prancis, Indonesia, Korea, Rusia, dan Portugis. Daftar ini berlaku untuk antarmuka dan edisi README; bukan berarti model Apple yang terpasang mendukung seluruh 11 bahasa.

## AI di perangkat

Percakapan, ekstraksi tambahan struk, dan komentar pengeluaran singkat menggunakan **SystemLanguageModel** bawaan Apple. Sistem operasi mengelola model dan pembaruannya. Tidak ada model alternatif, layar unduhan atau pemilihan model, atau koneksi ke Private Cloud Compute maupun penyedia AI cloud lain.

Percakapan meminta jawaban dalam bahasa pesan terbaru, terlepas dari bahasa antarmuka. Jika bahasa masukan tidak dapat dikenali, bahasa antarmuka digunakan. Bahasa yang didukung bergantung pada model Apple yang terpasang. Bahasa percakapan yang tidak didukung memunculkan pesan yang jelas: coba bahasa yang didukung model tersebut. Komentar pengeluaran meminta bahasa antarmuka, lalu menggabungkan lelucon dari AI dengan tindakan berdasarkan catatan; tips lokal digunakan jika pembuatan tidak tersedia.

## Catatan, struk, dan cadangan

Catatan keuangan dan gambar struk disimpan di perangkat. Di **Beranda → Pengaturan → Pengelolaan Data**, ekspor dompet, pemasukan, pengeluaran, transaksi berulang, dan kategori sebagai JSON. Popup menampilkan ukuran gambar terkait dan menawarkan ekspor dengan gambar atau catatan saja. Gambar yang dipakai bersama disertakan sekali. Pengodean JSON menambah ukuran data gambar sekitar **33%**.

Pemulihan mengganti catatan saat ini. Cadangan dengan gambar memulihkan data gambar asli; cadangan catatan saja tidak dapat memulihkan gambar. Cadangan lama tetap dapat dibaca, tetapi riwayat percakapan di dalamnya diabaikan. Banyak gambar dapat membutuhkan memori besar saat ekspor atau pemulihan.

**Riwayat percakapan tidak disertakan dalam ekspor apa pun.** Pesan kedaluwarsa **24 jam** setelah dibuat. Wealthy menghapus pesan kedaluwarsa saat berjalan dan memeriksa saat dimulai serta kembali ke latar depan. Jika iOS menangguhkan atau menghentikan aplikasi, penghapusan dilakukan saat aplikasi berjalan lagi. Pesan kedaluwarsa tidak ditampilkan atau dimasukkan ke konteks AI.

OCR struk ditujukan untuk **teks Jepang dan Inggris**. Ekstraksi jumlah otomatis ditujukan untuk **yen Jepang bilangan bulat**; mata uang asing perlu dimasukkan manual. Jumlah dan tanggal berasal dari pengurai OCR, bukan tebakan AI. Tanggal tercetak yang terbaca digunakan; jika tidak, tanggal saat pemindaian kamera kembali sebelum pengenalan dimulai digunakan dan ditandai untuk diperiksa. Kategori yang sesuai digunakan kembali atau dibuat jika diperlukan. Semua hasil dapat diedit.

Dalam pengukuran pada iPhone 16 Pro Max dengan iOS 27.2 menggunakan **15 gambar pengembangan yang sama**, total JPY cocok pada **6/10** kasus yang terbaca; empat lainnya belum terkonfirmasi. Tanggal tercetak cocok **14/14**, dan kategori hibrida cocok pada **14/14 sampel berlabel**; tingkat kesalahan karakter pada baris terpilih tetap **11.22%**. Gambar yang sama juga dipakai saat pengembangan: ini bukan hasil uji independen atau perkiraan akurasi struk baru. Lihat [laporan pengukuran](Verification/ReceiptImageOCR/RESULTS.md) untuk hasil macOS historis, pengecualian, dan rincian. Selalu periksa sebelum menyimpan.

## Membangun dari sumber

Gunakan Xcode dengan **SDK iOS 26 atau lebih baru**. Build pengembangan diperiksa dengan **Xcode 27.0**. Buka `Wealthy/Wealthy.xcodeproj`, pilih skema **Wealthy**, atur tim penandatanganan, dan jalankan pada iPhone atau iPad yang kompatibel. Proyek menggunakan framework sistem Apple tanpa dependensi paket Swift eksternal.

Pemeriksaan pada iPhone 16 Pro Max dengan iOS 27.2 mengonfirmasi balasan AI dalam bahasa Jepang dan Inggris, serta operasi lokal pengeluaran, dompet, kartu poin, dan dialog pencadangan. Perangkat lain dan alur kerja yang belum diuji masih belum terverifikasi. Lihat [petunjuk verifikasi](Verification/README.md).

**Prarilis v0.1.1** memuat kode sumber yang dijelaskan di sini. Unduhan aplikasi bertanda tangan tidak disediakan; baca batas verifikasi di atas sebelum melakukan build.

## Lisensi

Seluruh hak dilindungi. Redistribusi kode sumber atau biner memerlukan izin.
