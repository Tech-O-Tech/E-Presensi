//
//  SmileCameraView.swift
//  E-Presensi
//
//  Setara SmileCameraActivity Android — liveness senyum + kedip
//

import SwiftUI
import AVFoundation
import Vision
import UIKit
import Combine
import Foundation

struct SmileCameraView: View {
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void

    var body: some View {
        SmileCameraRepresentable(onCapture: onCapture, onCancel: onCancel)
            .ignoresSafeArea()
    }
}

// MARK: - UIKit Camera + Vision

private struct SmileCameraRepresentable: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> SmileCameraViewController {
        let vc = SmileCameraViewController()
        vc.onCapture = onCapture
        vc.onCancel = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: SmileCameraViewController, context: Context) {}
}

final class SmileCameraViewController: UIViewController {

    var onCapture: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let visionQueue = DispatchQueue(label: "smile.camera.vision")

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isTakingPhoto = false

    // Liveness state (sama Android)
    private var smileConfirmed = false
    private var blinkDetected = false
    private var winkDetected = false
    private var lastBothEyesOpen = true
    private var lastLeftOpen = true
    private var lastRightOpen = true
    private var lastStatus = ""

    /// Lebih sensitif dari default Android (0.3 / 0.7) agar kedip cepat terdeteksi.
    private let eyeClosedThreshold: Float = 0.48
    private let eyeOpenThreshold: Float = 0.52
    private let smileRatioThreshold: Float = 0.48

    private let statusLabel = UILabel()
    private let hintLabel = UILabel()
    private let stepLabel = UILabel()
    private let dotSmile = UIView()
    private let dotBlink = UIView()
    private let faceFrameView = UIView()
    private let closeButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        checkPermissionAndStart()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    // MARK: - UI

    private func setupUI() {
        faceFrameView.layer.borderWidth = 3
        faceFrameView.layer.borderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        faceFrameView.layer.cornerRadius = 130
        faceFrameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(faceFrameView)

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        let panel = UIView()
        panel.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)

        [dotSmile, dotBlink].forEach {
            $0.layer.cornerRadius = 6
            $0.translatesAutoresizingMaskIntoConstraints = false
            panel.addSubview($0)
        }

        [statusLabel, hintLabel, stepLabel].forEach {
            $0.textColor = .white
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.translatesAutoresizingMaskIntoConstraints = false
            panel.addSubview($0)
        }
        statusLabel.font = .boldSystemFont(ofSize: 22)
        hintLabel.font = .systemFont(ofSize: 14)
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        stepLabel.font = .systemFont(ofSize: 13)
        stepLabel.textColor = UIColor.white.withAlphaComponent(0.65)

        NSLayoutConstraint.activate([
            faceFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            faceFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            faceFrameView.widthAnchor.constraint(equalToConstant: 260),
            faceFrameView.heightAnchor.constraint(equalToConstant: 340),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dotSmile.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16),
            dotSmile.centerXAnchor.constraint(equalTo: panel.centerXAnchor, constant: -12),
            dotSmile.widthAnchor.constraint(equalToConstant: 12),
            dotSmile.heightAnchor.constraint(equalToConstant: 12),

            dotBlink.centerYAnchor.constraint(equalTo: dotSmile.centerYAnchor),
            dotBlink.leadingAnchor.constraint(equalTo: dotSmile.trailingAnchor, constant: 10),
            dotBlink.widthAnchor.constraint(equalToConstant: 12),
            dotBlink.heightAnchor.constraint(equalToConstant: 12),

            stepLabel.topAnchor.constraint(equalTo: dotSmile.bottomAnchor, constant: 10),
            stepLabel.centerXAnchor.constraint(equalTo: panel.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: stepLabel.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -24),

            hintLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            hintLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])

        updateUI(status: "Arahkan wajah ke kamera", hint: "Posisikan wajah di dalam bingkai oval", step: 0)
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    private func updateUI(status: String, hint: String, step: Int) {
        guard lastStatus != status else { return }
        lastStatus = status
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.statusLabel.text = status
            self.hintLabel.text = hint
            self.stepLabel.text = "Langkah \(step + 1) dari 2"

            let active = UIColor.systemBlue
            let inactive = UIColor.white.withAlphaComponent(0.35)
            let done = UIColor.systemGreen

            if self.smileConfirmed {
                self.dotSmile.backgroundColor = done
            } else {
                self.dotSmile.backgroundColor = step >= 0 ? active : inactive
            }

            if step > 1 {
                self.dotBlink.backgroundColor = done
            } else if step == 1 {
                self.dotBlink.backgroundColor = active
            } else {
                self.dotBlink.backgroundColor = inactive
            }
        }
    }

    // MARK: - Camera

    private func checkPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.configureSession() }
                    else { self?.showPermissionDenied() }
                }
            }
        default:
            showPermissionDenied()
        }
    }

    private func showPermissionDenied() {
        updateUI(status: "Izin kamera diperlukan", hint: "Aktifkan di Pengaturan", step: 0)
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func takePhoto() {
        guard !isTakingPhoto else { return }
        isTakingPhoto = true
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Face analysis

    private func processFace(_ face: VNFaceObservation, imageWidth: CGFloat, imageHeight: CGFloat) {
        let box = face.boundingBox
        let cx = (box.midX) * imageWidth
        let cy = (1 - box.midY) * imageHeight
        let faceW = box.width * imageWidth

        if cx < imageWidth * 0.15 || cx > imageWidth * 0.85 ||
            cy < imageHeight * 0.15 || cy > imageHeight * 0.85 {
            updateUI(status: "Posisikan wajah di tengah", hint: "Geser kamera atau sesuaikan posisi Anda", step: 0)
            return
        }

        if faceW < imageWidth * 0.15 {
            updateUI(status: "Dekatkan wajah ke kamera", hint: "Maju lebih dekat agar wajah terlihat jelas", step: 0)
            return
        }

        if !smileConfirmed {
            if smileScore(face) > smileRatioThreshold {
                smileConfirmed = true
                updateUI(status: "Senyum terdeteksi ✓", hint: "Sekarang kedipkan mata Anda", step: 1)
            } else {
                updateUI(status: "Tersenyumlah", hint: "Tunjukkan senyuman natural ke kamera", step: 0)
            }
            return
        }

        let (lOpen, rOpen) = eyeOpenProbabilities(face)
        let bothOpen = lOpen > eyeOpenThreshold && rOpen > eyeOpenThreshold
        let leftClosed = lOpen < eyeClosedThreshold
        let rightClosed = rOpen < eyeClosedThreshold

        // Foto langsung saat kedip terdeteksi (tidak perlu menunggu mata terbuka lagi).
        let blinkNow = lastBothEyesOpen && leftClosed && rightClosed
        let winkNow = (lastLeftOpen && leftClosed && rOpen > eyeOpenThreshold)
            || (lastRightOpen && rightClosed && lOpen > eyeOpenThreshold)

        if (blinkNow || winkNow || blinkDetected || winkDetected) && !isTakingPhoto {
            blinkDetected = true
            updateUI(status: "Kedip terdeteksi ✓  Mengambil foto...", hint: "Mohon tetap diam sebentar", step: 1)
            DispatchQueue.main.async { [weak self] in self?.takePhoto() }
            lastBothEyesOpen = bothOpen
            lastLeftOpen = lOpen > eyeOpenThreshold
            lastRightOpen = rOpen > eyeOpenThreshold
            return
        }

        updateUI(status: "Kedipkan mata", hint: "Kedipkan satu atau dua mata secara natural — foto diambil otomatis", step: 1)

        lastBothEyesOpen = bothOpen
        lastLeftOpen = lOpen > eyeOpenThreshold
        lastRightOpen = rOpen > eyeOpenThreshold
    }

    /// Rasio lebar/tinggi bibir — korelasi dengan senyum (setara smilingProbability > 0.6)
    private func smileScore(_ face: VNFaceObservation) -> Float {
        guard let lips = face.landmarks?.outerLips else { return 0 }
        let pts = lips.normalizedPoints
        guard pts.count >= 4 else { return 0 }
        let xs = pts.map(\.x)
        let ys = pts.map(\.y)
        let w = (xs.max() ?? 0) - (xs.min() ?? 0)
        let h = max((ys.max() ?? 0) - (ys.min() ?? 0), 0.001)
        return Float(w / h)
    }

    private func eyeOpenProbabilities(_ face: VNFaceObservation) -> (Float, Float) {
        let left = eyeOpenness(face.landmarks?.leftEye)
        let right = eyeOpenness(face.landmarks?.rightEye)
        return (left, right)
    }

    private func eyeOpenness(_ region: VNFaceLandmarkRegion2D?) -> Float {
        guard let region else { return 1 }
        let pts = region.normalizedPoints
        guard pts.count >= 4 else { return 1 }
        let ys = pts.map(\.y)
        let xs = pts.map(\.x)
        let v = (ys.max() ?? 0) - (ys.min() ?? 0)
        let h = max((xs.max() ?? 0) - (xs.min() ?? 0), 0.001)
        return Float(min(v / h * 5, 1))
    }
}

// MARK: - Video frames

extension SmileCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard !isTakingPhoto,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let self else { return }
            let faces = (req.results as? [VNFaceObservation]) ?? []
            let w = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
            let h = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

            switch faces.count {
            case 0:
                self.updateUI(
                    status: "Wajah tidak terdeteksi",
                    hint: "Pastikan wajah Anda terlihat jelas di kamera",
                    step: self.smileConfirmed ? 1 : 0
                )
            case 1:
                self.processFace(faces[0], imageWidth: w, imageHeight: h)
            default:
                self.updateUI(
                    status: "Hanya 1 wajah yang diperbolehkan",
                    hint: "Pastikan tidak ada orang lain di belakang Anda",
                    step: self.smileConfirmed ? 1 : 0
                )
            }
        }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )
        try? handler.perform([request])
    }
}

// MARK: - Photo capture

extension SmileCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        isTakingPhoto = false
        if error != nil {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI(status: "Gagal mengambil foto", hint: "Coba lagi", step: 1)
            }
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        smileConfirmed = false
        blinkDetected = false
        winkDetected = false
        lastBothEyesOpen = true
        lastLeftOpen = true
        lastRightOpen = true

        DispatchQueue.main.async { [weak self] in
            self?.onCapture?(image)
        }
    }
}
