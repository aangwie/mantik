# Mantik - Aplikasi Manajemen MikroTik Mobile

Mantik adalah aplikasi mobile responsif berbasis Flutter yang dirancang untuk mempermudah manajemen dan pemantauan jarak jauh Router MikroTik Anda via RouterOS API. Dengan antarmuka seluler yang modern dan intuitif, Anda dapat mengatur fungsi-fungsi administrasi dasar ISP maupun jaringan lokal (*Home Network*) dari mana saja.

## Fitur Utama

- 🏠 **Smart Dashboard**:
  - **Ringkasan PPPoE**: Pantau secara cepat informasi jumlah total, koneksi pengguna yang aktif, dan pengguna yang sedang *offline* (dikalkulasi secara akurat dan responsif).
  - **Monitor Trafik Fisik (*Real-time*)**: Menyajikan visualisasi grafik modern interaktif (`Rx / Tx`) untuk memantau beban trafik aktual (*bandwidth*) pada setiap *interface* fisik atau logika Anda (seperti *Ethernet, WLAN, Bridge, VLAN*, dll).

- 🛡️ **Manajemen Keamanan Firewall Lengkap (Berbasis CRUD)**:
  Sistem kontrol penuh layaknya *Winbox* di genggaman Anda. Modul antarmuka yang cerdas dan terpilah dalam bentuk Tab mendukung pengeditan konfigurasi tingkat lanjut:
  - **Filter Rules, NAT, Mangle, RAW**: Tambah (*Add*), Edit, Hapus (*Delete*), Aktifkan/Matikan aturan dengan *form input* universal (`Chain, Action, Address, Port, Protocol, Comment`).
  - **Address List**: Manajemen transisi form otomatis khusus (`List Name, Address, Timeout`).
  - Mendeteksi dan mengunci modifikasi untuk aturan-*aturan sistem Firewall berstatus "Dynamic"*.

- 👥 **Manajemen Klien PPPoE (Users & Secrets)**:
  - Kemampuan mengatur dan mendaftarkan anggota PPPoE (Secret) ke dalam *router*.
  - Dilengkapi navigasi **Dropdown Dinamis** untuk memilih paket **Profile** dan **Service** yang terintegrasi secara *real-time* langsung dari tabel konfigurasi *Router*.
  - Dilengkapi *Filter Status* (Hanya Tampilkan *Active*, *Offline*, atau Semua Klien) dan pelabelan *Badge Status Aktif/Offline*.

- 🚀 **Pemantauan Kapasitas Simple Queue (*Bandwidth Control*)**:
  - Melihat secara menyeluruh batas target maksimal unggah/unduh (*Upload/Download Maximum Limit*) tiap antrean/klien.
  - **Pemantauan Kecepatan Antrean Transparan**: Ketuk baris pengguna Simple Queue mana pun di *list*, lalu aplikasi akan membuka jendela eksklusif yang menarik data transfer *bandwidth* (*rate Rx/Tx*) spesifik dari *queue* tersebut yang bergerak dinamis.

## Teknologi Utama
- **Framework**: Flutter (Bahasa Pemrograman: Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Visualisasi Grafik**: FL Chart (`fl_chart`) untuk merender *Line-Chart* yang halus.
- **Komunikasi MikroTik**: Sistem menggunakan paket API `router_os_client` untuk mentransmisikan jalur komunikasi soket dan pertukaran *data mapping* tanpa jeda.

## Cara Menggunakan
1. Pastikan fitur **API Service** di dalam mikroTik *Router* telah diaktifkan (`/ip service enable api`, *Port default* biasanya **8728**).
2. Bangun (*build* apk) dan buka aplikasi Mantik di *Smartphone* Anda.
3. Anda dapat menjaga beberapa **Profil Login** dari beragam router ke aplikasi untuk dikelola cepat *(Save Profile)*.
4. Autentikasikan menggunakan kredensial berupa alamat *Host/IP*, *API Port*, *Username*, dan *Password* MikroTik.
5. Gunakan menu *Drawer Navigation* samping dan kelola operasi MikroTik semudah menggunakan Winbox dengan cara yang portabel!
