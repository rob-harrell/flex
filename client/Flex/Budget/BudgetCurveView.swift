//
//  BudgetCurveView.swift
//  Flex
//
//  Created by Rob Harrell on 6/6/24.
//

import Foundation
import SwiftUI
import UIKit

struct BudgetCurveView: UIViewRepresentable {
    var dataPoints: [CGFloat]

    func makeUIView(context: Context) -> UIView {
        let view = CurveView(dataPoints: dataPoints)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let curveView = uiView as? CurveView else { return }
        curveView.dataPoints = dataPoints
        uiView.setNeedsDisplay()
    }

    class CurveView: UIView {
        var dataPoints: [CGFloat]

        init(dataPoints: [CGFloat]) {
            self.dataPoints = dataPoints
            super.init(frame: .zero)
            self.backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ rect: CGRect) {
            let fillPath = UIBezierPath()
            let strokePath = UIBezierPath()
            let step = rect.width / CGFloat(2) // Divide by 2 because there are 2 steps between 3 points

            // Starting point
            var x: CGFloat = 0
            var y: CGFloat = rect.height - (dataPoints[0] * rect.height)
            fillPath.move(to: CGPoint(x: x, y: y))
            strokePath.move(to: CGPoint(x: x, y: y))

            // Control point
            x += step
            y = rect.height - (dataPoints[1] * rect.height)
            if dataPoints[1] > 0.9 {
                y += 1
            }
            if dataPoints[1] > 0.95 {
                y += 1
            }
            if dataPoints[1] == 1.0 {
                y += 2 // Additional 1px to make it total 3px
            }

            // End point
            let endX = x + step
            let endY = rect.height - (dataPoints[2] * rect.height)
            fillPath.addQuadCurve(to: CGPoint(x: endX, y: endY), controlPoint: CGPoint(x: x, y: y))
            strokePath.addQuadCurve(to: CGPoint(x: endX, y: endY), controlPoint: CGPoint(x: x, y: y))

            // Close the fill path
            fillPath.addLine(to: CGPoint(x: endX, y: rect.height))
            fillPath.addLine(to: CGPoint(x: 0, y: rect.height))
            fillPath.close()

            // Fill the path
            UIColor.slate500.withAlphaComponent(0.4).setFill() // Change the color and transparency as needed
            fillPath.fill()

            // Stroke the path
            strokePath.lineWidth = 1
            UIColor.slate500.withAlphaComponent(0.4).setStroke() 
            strokePath.stroke()
        }
    }   
}
