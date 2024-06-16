//
//  BudgetCurveView.swift
//  Flex
//
//  Created by Rob Harrell on 6/6/24.
//

import Foundation
import SwiftUI
import UIKit

struct BudgetCurveView: View {
    var dataPoints: [CGFloat]

    var body: some View {
        GeometryReader { geometry in
            let curveShape = CurveShape(dataPoints: dataPoints, rect: geometry.frame(in: .local))
            curveShape
                .fill(Color(.slate200).opacity(0.4))
                .overlay(
                    TopLineShape(curveShape: curveShape)
                        .stroke(Color(.slate500).opacity(1), style: StrokeStyle(lineWidth: 0.5, lineCap: .round, lineJoin: .round))
                )
        }
    }

    struct CurveShape: Shape {
        var dataPoints: [CGFloat]
        var rect: CGRect

        func path(in rect: CGRect) -> Path {
            var path = createPath(in: rect)
            // Close the path
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.closeSubpath()
            return path
        }

        func createPath(in rect: CGRect) -> Path {
            var path = Path()
            let step = rect.width / CGFloat(2) // Divide by 2 because there are 2 steps between 3 points

            // Starting point
            var x: CGFloat = 0
            var y: CGFloat = rect.height - (dataPoints[0] * rect.height)
            path.move(to: CGPoint(x: x, y: y))

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
            path.addQuadCurve(to: CGPoint(x: endX, y: endY), control: CGPoint(x: x, y: y))

            return path
        }
    }

    struct TopLineShape: Shape {
        var curveShape: CurveShape

        func path(in rect: CGRect) -> Path {
            return curveShape.createPath(in: rect)
        }
    }
}
