//
//  ApiService.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//
import Foundation
import UIKit
import Combine

class ApiService {
    
    // MARK: - GENERIC REQUEST
    private static func request<T: Decodable>(
            url: URL,
            method: String = "GET",
            headers: [String: String] = [:],
            body: Data? = nil,
            completion: @escaping (T?, Error?) -> Void // Menambahkan Error parameter
        ) {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.httpBody = body
            request.timeoutInterval = 15 // Timeout untuk menghindari loading selamanya
            
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                // Jika ada error jaringan (seperti -1003 Hostname not found)
                if let error = error {
                    DispatchQueue.main.async { completion(nil, error) }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async { completion(nil, nil) }
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    DispatchQueue.main.async { completion(result, nil) }
                } catch {
                    #if DEBUG
                    if let raw = String(data: data, encoding: .utf8) {
                        print("Decoding Error: \(error)")
                        print("Response body: \(raw.prefix(800))")
                    }
                    #endif
                    DispatchQueue.main.async { completion(nil, error) }
                }
            }.resume()
        }
    
    // MARK: - LOGIN
    static func login(nip: String, password: String, deviceId: String, completion: @escaping (LoginResponse?, Error?) -> Void) {
        guard let url = URL(string: Constants.baseURL + "login") else {
            completion(nil, URLError(.badURL))
            return
        }

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "nip_pegawai", value: nip),
            URLQueryItem(name: "password", value: password),
            URLQueryItem(name: "device_id", value: deviceId)
        ]
        let body = components.percentEncodedQuery?.data(using: .utf8)

        request(
            url: url,
            method: "POST",
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: body,
            completion: completion
        )
    }
    
    // MARK: - CHECK UPDATE
    static func checkUpdate(completion: @escaping (AppVersionResponse?, Error?) -> Void) {
            let url = URL(string: Constants.baseURL + "appversion/check/latest?platform=ios")!
            request(url: url, completion: completion)
        }
    
    // MARK: - OPD
    static func getOpd(token: String, idOpd: String, completion: @escaping (Opd?, Error?) -> Void) {
        let url = URL(string: Constants.baseURL + "opd/\(idOpd)")!
        
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }
    
    
    static func getAllOpd(completion: @escaping (OpdAll?, Error?) -> Void) {
        let url = URL(string: Constants.baseURL + "opd")!
        request(url: url, completion: completion)
    }
    
    // MARK: - PRESENSI
    static func getPresensi(token: String, idPegawai: String, completion: @escaping (Presensi?, Error?) -> Void) {
        let url = URL(string: Constants.baseURL + "presensi/today/\(idPegawai)")!
        
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    static func tambahIzin(
        token: String,
        idPegawai: String,
        idOpd: String,
        keterangan: String,
        tanggalIzin: String,
        tanggalSelesai: String,
        jenisIzin: String,
        fileURL: URL,
        completion: @escaping (DefaultResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "izin") else {
            completion(nil, URLError(.badURL))
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let params: [String: String] = [
            "id_pegawai": idPegawai,
            "id_opd": idOpd,
            "keterangan": keterangan,
            "tanggal_izin": tanggalIzin,
            "tanggal_selesai": tanggalSelesai,
            "jenis_izin": jenisIzin
        ]

        guard let body = multipartBodyWithFile(
            params: params,
            fileURL: fileURL,
            fileFieldName: "bukti_izin",
            boundary: boundary
        ) else {
            completion(nil, URLError(.cannotOpenFile))
            return
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(nil, URLError(.badServerResponse)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(DefaultResponse.self, from: data)
                DispatchQueue.main.async { completion(result, nil) }
            } catch {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }

    static func checkIzinHariIni(
        token: String,
        idPegawai: String,
        completion: @escaping (DefaultResponse?, Error?) -> Void
    ) {
        let url = URL(string: Constants.baseURL + "izin/hari-ini/\(idPegawai)")!
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    /// Ambil detail izin hari ini (`tanggal_izin`, `keterangan`, `verifikasi`, dll).
    /// Endpoint: `GET izin/hari-ini/{id_pegawai}` — sama dengan `checkIzinHariIni`,
    /// tetapi memetakan ke `IzinTodayResponse` agar bisa menampilkan rekap.
    static func getIzinHariIni(
        token: String,
        idPegawai: String,
        completion: @escaping (IzinTodayResponse?, Error?) -> Void
    ) {
        let url = URL(string: Constants.baseURL + "izin/hari-ini/\(idPegawai)")!
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    /// Ambil data absen khusus hari ini (Khusus Lisan / DL Dalam / DL Luar Kabupaten).
    /// Endpoint: `GET absen-khusus/hari-ini/{id_pegawai}`
    static func getAbsenKhususHariIni(
        token: String,
        idPegawai: String,
        completion: @escaping (AbsenKhususResponse?, Error?) -> Void
    ) {
        let url = URL(string: Constants.baseURL + "absen-khusus/hari-ini/\(idPegawai)")!
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    // MARK: - REKAP (RIWAYAT) LIST

    /// Riwayat presensi per BULAN.
    /// Endpoint: `GET presensi?id_opd=&id_pegawai=&bulan=&tahun=` (controller listPresensi).
    static func getPresensiList(
        token: String,
        idOpd: String,
        idPegawai: String,
        bulan: String,
        tahun: String,
        completion: @escaping (PresensiListResponse?, Error?) -> Void
    ) {
        var components = URLComponents(string: Constants.baseURL + "presensi")
        components?.queryItems = [
            URLQueryItem(name: "id_opd", value: idOpd),
            URLQueryItem(name: "id_pegawai", value: idPegawai),
            URLQueryItem(name: "bulan", value: bulan),
            URLQueryItem(name: "tahun", value: tahun)
        ]
        guard let url = components?.url else {
            completion(nil, URLError(.badURL))
            return
        }
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    /// Riwayat izin pegawai (server kembalikan semua; filter bulan dilakukan di client).
    /// Endpoint: `GET izin?id_pegawai=` (controller listIzin).
    static func getIzinList(
        token: String,
        idPegawai: String,
        completion: @escaping (IzinListResponse?, Error?) -> Void
    ) {
        var components = URLComponents(string: Constants.baseURL + "izin")
        components?.queryItems = [
            URLQueryItem(name: "id_pegawai", value: idPegawai)
        ]
        guard let url = components?.url else {
            completion(nil, URLError(.badURL))
            return
        }
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    // MARK: - PROFIL

    static func editFotoProfil(
        token: String,
        nipPegawai: String,
        image: UIImage,
        completion: @escaping (Pegawai?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "pegawai/\(nipPegawai)") else {
            completion(nil, URLError(.badURL))
            return
        }
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = multipartBody(params: [:], images: ["foto": image], boundary: boundary)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(nil, URLError(.badServerResponse)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(Pegawai.self, from: data)
                DispatchQueue.main.async { completion(result, nil) }
            } catch {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }

    static func buatComplaint(
        token: String,
        idPegawai: String,
        idOpd: String,
        tujuan: String,
        isi: String,
        fileURL: URL,
        completion: @escaping (DefaultResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "complaint") else {
            completion(nil, URLError(.badURL))
            return
        }
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let params: [String: String] = [
            "id_pegawai": idPegawai,
            "id_opd": idOpd,
            "tujuan": tujuan,
            "isi": isi
        ]
        guard let body = multipartBodyWithFile(
            params: params,
            fileURL: fileURL,
            fileFieldName: "bukti_complaint",
            boundary: boundary
        ) else {
            completion(nil, URLError(.cannotOpenFile))
            return
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(nil, URLError(.badServerResponse)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(DefaultResponse.self, from: data)
                DispatchQueue.main.async { completion(result, nil) }
            } catch {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }

    // MARK: - KEGIATAN
    static func getKegiatan(token: String, idPegawai: String, completion: @escaping (KegiatanResponse?, Error?) -> Void) {
        let url = URL(string: Constants.baseURL + "kegiatan/today/\(idPegawai)")!
        
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }
    
    static func buatKegiatan(
        token: String,
        idPegawai: String,
        idPresensi: String,
        kegiatan: String,
        tanggal: String,
        fileURL: URL,
        completion: @escaping (KegiatanResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "kegiatan") else {
            completion(nil, URLError(.badURL))
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let params: [String: String] = [
            "id_pegawai": idPegawai,
            "id_presensi": idPresensi,
            "kegiatan": kegiatan,
            "tanggal_kegiatan": tanggal
        ]
        
        guard let body = multipartBodyWithFile(
            params: params,
            fileURL: fileURL,
            fileFieldName: "file",
            boundary: boundary
        ) else {
            completion(nil, URLError(.cannotOpenFile))
            return
        }
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(nil, URLError(.badServerResponse)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(KegiatanResponse.self, from: data)
                DispatchQueue.main.async { completion(result, nil) }
            } catch {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    private static func multipartBodyWithFile(
        params: [String: String],
        fileURL: URL,
        fileFieldName: String,
        boundary: String
    ) -> Data? {
        guard let fileData = try? Data(contentsOf: fileURL) else { return nil }
        
        let ext = fileURL.pathExtension.lowercased()
        let mime: String
        switch ext {
        case "pdf": mime = "application/pdf"
        case "jpg", "jpeg": mime = "image/jpeg"
        case "png": mime = "image/png"
        default: mime = "application/octet-stream"
        }
        
        var body = Data()
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // MARK: - MULTIPART HELPER
    private static func multipartBody(
        params: [String: String],
        images: [String: UIImage],
        boundary: String
    ) -> Data {
        
        var body = Data()
        
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        for (key, image) in images {
            let imageData = image.jpegData(compressionQuality: 0.8)!
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // MARK: - PRESENSI (setara PresensiActivity Android)

    static func tandaiJamMasuk(
        token: String,
        idPegawai: String,
        keterangan: String,
        image: UIImage,
        completion: @escaping (Presensi?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "presensi") else {
            completion(nil, URLError(.badURL))
            return
        }
        uploadPresensi(
            url: url,
            method: "POST",
            token: token,
            params: ["id_pegawai": idPegawai, "ket_masuk": keterangan],
            imageField: "foto_masuk",
            image: image,
            completion: completion
        )
    }

    static func tandaiJamSiang(
        token: String,
        idPresensi: String,
        idPegawai: String,
        keterangan: String,
        image: UIImage,
        completion: @escaping (Presensi?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "presensi/siang/\(idPresensi)") else {
            completion(nil, URLError(.badURL))
            return
        }
        uploadPresensi(
            url: url,
            method: "PUT",
            token: token,
            params: ["ket_siang": keterangan, "edited_by": idPegawai],
            imageField: "foto_siang",
            image: image,
            completion: completion
        )
    }

    static func tandaiJamPulang(
        token: String,
        idPresensi: String,
        idPegawai: String,
        keterangan: String,
        image: UIImage,
        completion: @escaping (Presensi?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "presensi/pulang/\(idPresensi)") else {
            completion(nil, URLError(.badURL))
            return
        }
        uploadPresensi(
            url: url,
            method: "PUT",
            token: token,
            params: ["ket_pulang": keterangan, "edited_by": idPegawai],
            imageField: "foto_pulang",
            image: image,
            completion: completion
        )
    }

    private static func uploadPresensi(
        url: URL,
        method: String,
        token: String,
        params: [String: String],
        imageField: String,
        image: UIImage,
        completion: @escaping (Presensi?, Error?) -> Void
    ) {
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = multipartBody(
            params: params,
            images: [imageField: image],
            boundary: boundary
        )

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(nil, URLError(.badServerResponse)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(Presensi.self, from: data)
                DispatchQueue.main.async { completion(result, nil) }
            } catch {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    // MARK: - WFH
    static func setWFH(
        token: String,
        idPegawai: String,
        lat: String,
        long: String,
        completion: @escaping (Bool, Int?, String?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "wfh") else {
            completion(false, nil, "URL tidak valid")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = multipartBody(
            params: ["id_pegawai": idPegawai, "lat": lat, "long": long],
            images: [:],
            boundary: boundary
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                DispatchQueue.main.async { completion(false, nil, error.localizedDescription) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(false, nil, "Tidak ada respons") }
                return
            }
            if let decoded = try? JSONDecoder().decode(DefaultResponse.self, from: data) {
                let ok = decoded.code == 200 || decoded.code == 201
                DispatchQueue.main.async { completion(ok, decoded.code, decoded.message) }
            } else if let http = response as? HTTPURLResponse {
                DispatchQueue.main.async { completion(http.statusCode == 200, http.statusCode, nil) }
            } else {
                DispatchQueue.main.async { completion(false, nil, "Gagal decode respons") }
            }
        }.resume()
    }

    static func getLocation(
        token: String,
        idPegawai: String,
        completion: @escaping (WfhResponse?, Error?) -> Void
    ) {
        let url = URL(string: Constants.baseURL + "wfh/\(idPegawai)")!
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    /// Parse respons WFH — prioritaskan koordinat valid (sama Android: HTTP sukses + ada lat/long).
    static func fetchWfhLocation(
        token: String,
        idPegawai: String,
        completion: @escaping (_ found: Bool, _ lat: Double?, _ lng: Double?) -> Void
    ) {
        let trimmedId = idPegawai.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty,
              let url = URL(string: Constants.baseURL + "wfh/\(trimmedId)") else {
            DispatchQueue.main.async { completion(false, nil, nil) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(bearerToken(token), forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data, error == nil else {
                DispatchQueue.main.async { completion(false, nil, nil) }
                return
            }

            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .sessionExpired, object: nil)
                    completion(false, nil, nil)
                }
                return
            }

            #if DEBUG
            if let raw = String(data: data, encoding: .utf8) {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[WFH] GET wfh/\(trimmedId) HTTP=\(status) body=\(raw.prefix(600))")
            }
            #endif

            let result = parseWfhLocationPayload(data, httpStatus: (response as? HTTPURLResponse)?.statusCode)
            DispatchQueue.main.async { completion(result.found, result.lat, result.lng) }
        }.resume()
    }

    private static func bearerToken(_ token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("bearer ") { return trimmed }
        return "Bearer \(trimmed)"
    }

    private static func parseWfhLocationPayload(
        _ data: Data,
        httpStatus: Int?
    ) -> (found: Bool, lat: Double?, lng: Double?) {
        if let json = try? JSONSerialization.jsonObject(with: data) {
            if let coords = findWfhCoordinates(in: json) {
                return (true, coords.lat, coords.lng)
            }
        }

        if let decoded = try? JSONDecoder().decode(WfhResponse.self, from: data),
           let lat = decoded.data?.lat,
           let lng = decoded.data?.long,
           lat != 0, lng != 0 {
            return (true, lat, lng)
        }

        if httpStatus == 404 {
            return (false, nil, nil)
        }

        return (false, nil, nil)
    }

    private static func findWfhCoordinates(in value: Any?) -> (lat: Double, lng: Double)? {
        if let dict = value as? [String: Any] {
            if let lat = firstCoordinate(in: dict, keys: ["lat", "latitude", "lat_rumah", "latRumah"]),
               let lng = firstCoordinate(in: dict, keys: ["long", "lng", "longitude", "long_rumah", "longRumah", "lng_rumah"]),
               lat != 0, lng != 0 {
                return (lat, lng)
            }
            for nested in dict.values {
                if let found = findWfhCoordinates(in: nested) { return found }
            }
        } else if let array = value as? [Any] {
            for item in array {
                if let found = findWfhCoordinates(in: item) { return found }
            }
        }
        return nil
    }

    private static func firstCoordinate(in dict: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let value = parseCoordinate(dict[key]) { return value }
        }
        return nil
    }

    private static func parseCoordinate(_ value: Any?) -> Double? {
        switch value {
        case let d as Double: return d
        case let i as Int: return Double(i)
        case let l as Int64: return Double(l)
        case let s as String:
            let normalized = s.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            return Double(normalized)
        case let n as NSNumber: return n.doubleValue
        default: return nil
        }
    }

    static func getKantor(
        token: String,
        idKantor: String,
        completion: @escaping (Kantor?, Error?) -> Void
    ) {
        let url = URL(string: Constants.baseURL + "kantor/\(idKantor)")!
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }

    static func tambahKhusus(
        token: String,
        idPegawai: String,
        idOpd: String,
        idAtasan: String,
        keterangan: String,
        tanggalMulai: String,
        tanggalAkhir: String,
        jenisKhusus: String,
        fileURL: URL,
        completion: @escaping (DefaultResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "absen-khusus") else {
            completion(nil, URLError(.badURL))
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let params: [String: String] = [
            "id_pegawai": idPegawai,
            "id_opd": idOpd,
            "id_atasan": idAtasan,
            "keterangan": keterangan,
            "tanggal_mulai": tanggalMulai,
            "tanggal_akhir": tanggalAkhir,
            "jenis_khusus": jenisKhusus
        ]

        guard let body = multipartBodyWithFile(
            params: params,
            fileURL: fileURL,
            fileFieldName: "file",
            boundary: boundary
        ) else {
            completion(nil, URLError(.cannotOpenFile))
            return
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            guard let data else {
                DispatchQueue.main.async { completion(nil, URLError(.badServerResponse)) }
                return
            }
            do {
                let result = try JSONDecoder().decode(DefaultResponse.self, from: data)
                DispatchQueue.main.async { completion(result, nil) }
            } catch {
                DispatchQueue.main.async { completion(nil, error) }
            }
        }.resume()
    }
    
    static func editOpd(
        token: String,
        nip: String,
        idOpd: String,
        completion: @escaping (DefaultResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: Constants.baseURL + "pegawai/opd/\(nip)") else {
            completion(nil, URLError(.badURL))
            return
        }
        let body = "id_opd=\(idOpd)"
        request(
            url: url,
            method: "PUT",
            headers: [
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": "Bearer \(token)"
            ],
            body: body.data(using: .utf8),
            completion: completion
        )
    }

    // MARK: - UBAH PASSWORD
    static func ubahPassword(token: String, nip: String, password: String, completion: @escaping (DefaultResponse?, Error?) -> Void) {
        
        let url = URL(string: Constants.baseURL + "ubah-password")!
        
        let body = "nip_pegawai=\(nip)&password=\(password)"
        
        request(
            url: url,
            method: "PUT",
            headers: [
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": "Bearer \(token)"
            ],
            body: body.data(using: .utf8),
            completion: completion
        )
    }
    
    // MARK: - REKAP IZIN (dengan filter tanggal)
    static func getIzinList(
        token: String,
        idPegawai: String,
        tanggalMulai: String? = nil,
        tanggalSelesai: String? = nil,
        completion: @escaping (IzinListResponse?, Error?) -> Void
    ) {
        var urlString = Constants.baseURL + "izin/\(idPegawai)"
        
        var components = URLComponents(string: urlString)
        var queryItems: [URLQueryItem] = []
        
        if let mulai = tanggalMulai, !mulai.isEmpty {
            queryItems.append(URLQueryItem(name: "tanggal_mulai", value: mulai))
        }
        if let selesai = tanggalSelesai, !selesai.isEmpty {
            queryItems.append(URLQueryItem(name: "tanggal_selesai", value: selesai))
        }
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            completion(nil, URLError(.badURL))
            return
        }
        
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }
    
    // MARK: - REKAP PRESENSI (dengan filter tanggal)
    static func getPresensiList(
        token: String,
        idPegawai: String,
        tanggalMulai: String? = nil,
        tanggalSelesai: String? = nil,
        completion: @escaping (PresensiListResponse?, Error?) -> Void
    ) {
        var components = URLComponents(string: Constants.baseURL + "presensi/\(idPegawai)")
        var queryItems: [URLQueryItem] = []
        
        if let mulai = tanggalMulai, !mulai.isEmpty {
            queryItems.append(URLQueryItem(name: "tanggal_mulai", value: mulai))
        }
        if let selesai = tanggalSelesai, !selesai.isEmpty {
            queryItems.append(URLQueryItem(name: "tanggal_selesai", value: selesai))
        }
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            completion(nil, URLError(.badURL))
            return
        }
        
        request(
            url: url,
            headers: ["Authorization": "Bearer \(token)"],
            completion: completion
        )
    }
}
