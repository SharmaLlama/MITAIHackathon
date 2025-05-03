//
//  FaceOutlineView.swift
//  SkinSnap
//
//  Created by Utkarsh sharma on 3/5/2025.
//


import SwiftUI

// MARK: - Face Region Views

// Base face outline
struct FaceOutlineView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw face outline (oval shape)
        path.addEllipse(in: CGRect(x: width * 0.1, y: height * 0.05, width: width * 0.8, height: height * 0.9))
        
        return path
    }
}

// Forehead region
struct ForeheadView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw forehead as upper part of the face
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.05))
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.05),
            control1: CGPoint(x: width * 0.3, y: height * -0.1),
            control2: CGPoint(x: width * 0.7, y: height * -0.1)
        )
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.3))
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.3),
            control1: CGPoint(x: width * 0.7, y: height * 0.25),
            control2: CGPoint(x: width * 0.3, y: height * 0.25)
        )
        path.closeSubpath()
        
        return path
    }
}

// Left cheek region
struct LeftCheekView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw left cheek
        path.move(to: CGPoint(x: width * 0.1, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.1, y: height * 0.7))
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.65),
            control1: CGPoint(x: width * 0.2, y: height * 0.7),
            control2: CGPoint(x: width * 0.25, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.35),
            control1: CGPoint(x: width * 0.35, y: height * 0.55),
            control2: CGPoint(x: width * 0.35, y: height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.1, y: height * 0.3),
            control1: CGPoint(x: width * 0.25, y: height * 0.35),
            control2: CGPoint(x: width * 0.2, y: height * 0.3)
        )
        path.closeSubpath()
        
        return path
    }
}

// Right cheek region
struct RightCheekView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw right cheek (mirror of left)
        path.move(to: CGPoint(x: width * 0.9, y: height * 0.3))
        path.addLine(to: CGPoint(x: width * 0.9, y: height * 0.7))
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.65),
            control1: CGPoint(x: width * 0.8, y: height * 0.7),
            control2: CGPoint(x: width * 0.75, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.35),
            control1: CGPoint(x: width * 0.65, y: height * 0.55),
            control2: CGPoint(x: width * 0.65, y: height * 0.45)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.9, y: height * 0.3),
            control1: CGPoint(x: width * 0.75, y: height * 0.35),
            control2: CGPoint(x: width * 0.8, y: height * 0.3)
        )
        path.closeSubpath()
        
        return path
    }
}

// Nose region
struct NoseView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw nose in the center
        path.move(to: CGPoint(x: width * 0.4, y: height * 0.35))
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.55))
        path.addCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.55),
            control1: CGPoint(x: width * 0.45, y: height * 0.6),
            control2: CGPoint(x: width * 0.55, y: height * 0.6)
        )
        path.addLine(to: CGPoint(x: width * 0.6, y: height * 0.35))
        path.addCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.35),
            control1: CGPoint(x: width * 0.55, y: height * 0.35),
            control2: CGPoint(x: width * 0.45, y: height * 0.35)
        )
        path.closeSubpath()
        
        return path
    }
}

// Chin region
struct ChinView: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        // Draw chin as bottom part of face
        path.move(to: CGPoint(x: width * 0.35, y: height * 0.65))
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.65),
            control1: CGPoint(x: width * 0.45, y: height * 0.65),
            control2: CGPoint(x: width * 0.55, y: height * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.9),
            control1: CGPoint(x: width * 0.68, y: height * 0.7),
            control2: CGPoint(x: width * 0.7, y: height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.95),
            control1: CGPoint(x: width * 0.65, y: height * 0.95),
            control2: CGPoint(x: width * 0.6, y: height * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height * 0.9),
            control1: CGPoint(x: width * 0.4, y: height * 0.95),
            control2: CGPoint(x: width * 0.35, y: height * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.65),
            control1: CGPoint(x: width * 0.3, y: height * 0.8),
            control2: CGPoint(x: width * 0.32, y: height * 0.7)
        )
        path.closeSubpath()
        
        return path
    }
}
