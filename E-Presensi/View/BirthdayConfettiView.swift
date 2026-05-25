//
//  BirthdayConfettiView.swift
//  E-Presensi
//
//  Letusan konfeti dari tengah layar, menyebar 360° selama ±7 detik
//

import SwiftUI
import UIKit

struct BirthdayConfettiView: UIViewRepresentable {

    var burstDuration: TimeInterval = 1.8
    var visibleDuration: TimeInterval = 7

    func makeCoordinator() -> Coordinator {
        Coordinator(burstDuration: burstDuration, visibleDuration: visibleDuration)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false

        let emitter = CAEmitterLayer()
        emitter.emitterShape = .point
        emitter.emitterMode = .outline
        emitter.renderMode = .additive
        emitter.emitterCells = makeCells()
        container.layer.addSublayer(emitter)
        context.coordinator.emitter = emitter
        context.coordinator.container = container

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let emitter = context.coordinator.emitter else { return }
        let bounds = uiView.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterSize = .zero

        if !context.coordinator.didStart {
            context.coordinator.didStart = true
            context.coordinator.startBurst()
        }
    }

    private func makeCells() -> [CAEmitterCell] {
        let palette: [UIColor] = [
            UIColor(red: 0xfc / 255, green: 0xe1 / 255, blue: 0x8a / 255, alpha: 1),
            UIColor(red: 0xff / 255, green: 0x72 / 255, blue: 0x6d / 255, alpha: 1),
            UIColor(red: 0xf4 / 255, green: 0x30 / 255, blue: 0x6d / 255, alpha: 1),
            UIColor(red: 0xb4 / 255, green: 0x8d / 255, blue: 0xef / 255, alpha: 1)
        ]

        return palette.enumerated().map { index, color in
            let cell = CAEmitterCell()
            cell.contents = ConfettiPiece.image(for: color, variant: index % 2)?.cgImage
            cell.birthRate = 55
            cell.lifetime = 5.5
            cell.lifetimeRange = 1.5
            cell.velocity = 320
            cell.velocityRange = 140
            cell.emissionRange = .pi * 2
            cell.emissionLongitude = 0
            cell.yAcceleration = 110
            cell.xAcceleration = 0
            cell.spin = 4
            cell.spinRange = 5
            cell.scale = 0.55
            cell.scaleRange = 0.3
            cell.scaleSpeed = -0.04
            cell.alphaSpeed = -0.12
            cell.alphaRange = 0.3
            return cell
        }
    }

    final class Coordinator {
        var emitter: CAEmitterLayer?
        var container: UIView?
        var didStart = false

        private let burstDuration: TimeInterval
        private let visibleDuration: TimeInterval

        init(burstDuration: TimeInterval, visibleDuration: TimeInterval) {
            self.burstDuration = burstDuration
            self.visibleDuration = visibleDuration
        }

        func startBurst() {
            emitter?.beginTime = CACurrentMediaTime()
            emitter?.birthRate = 1

            DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration) { [weak self] in
                self?.emitter?.birthRate = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + visibleDuration) { [weak self] in
                UIView.animate(withDuration: 0.35) {
                    self?.container?.alpha = 0
                } completion: { _ in
                    self?.emitter?.removeFromSuperlayer()
                    self?.emitter = nil
                }
            }
        }
    }
}

private enum ConfettiPiece {
    static func image(for color: UIColor, variant: Int) -> UIImage? {
        let size = variant == 0 ? CGSize(width: 10, height: 10) : CGSize(width: 8, height: 14)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            color.setFill()
            if variant == 0 {
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
            } else {
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2).fill()
            }
        }
    }
}
