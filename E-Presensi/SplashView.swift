import SwiftUI


// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            
            // Background putih
            Color.white
                .ignoresSafeArea()
            
            // MARK: - Wave bawah
            VStack {
                Spacer()
                
                ZStack {
                    // Layer belakang (lebih terang & turun)
                    WaveShape()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 300)
                        .offset(y: 40)
                    
                    // Layer depan (lebih gelap)
                    WaveShape()
                        .fill(Color.gray.opacity(0.25))
                        .frame(height: 280)
                        .offset(y: 70)
                }
            }
            .ignoresSafeArea()
            
            // MARK: - Konten utama
            VStack(spacing: 18) {
                
                Spacer()
                
                // Logo
                Image("logo_pringsewu")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                
                // Judul
                Text("E-Presensi")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.6))
                
                // Garis biru kecil
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 60, height: 4)
                
                // Deskripsi
                Text("Aplikasi Presensi Elektronik\nPemerintah Daerah\nKabupaten Pringsewu")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                
                Spacer()
                
                // Loading
                VStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    
                    Text("Memuat...")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Spacer().frame(height: 30)
            }
            .padding()
        }
    }
}
