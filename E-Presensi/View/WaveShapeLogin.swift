//
//  WaveShapeLogin.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 22/04/26.
//

import SwiftUI

struct WaveShapeLogin: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 50))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: 50),
            control: CGPoint(x: rect.width / 2, y: 120)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}
