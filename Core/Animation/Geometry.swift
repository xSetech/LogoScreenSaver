// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A closed, directed line segment from p₀ to p₁
public class Ray {

    public let p₀: CGPoint
    public let p₁: CGPoint

    public init(p₀: CGPoint, p₁: CGPoint) {
        self.p₀ = p₀
        self.p₁ = p₁
    }

    /// Displacement vector from p₀ to p₁
    public var vector: CGVector {
        p₁ - p₀
    }

    public var length: CGFloat {
        vector.magnitude
    }

    public func point(at t: CGFloat) -> CGPoint {
        p₀ + (vector * t)
    }

    /// Intersections with rect edges, sorted by time
    public func intersections(with rect: CGRect) -> [Intersection] {
        var candidates: [Intersection] = []

        // Horizontal edges
        if vector.dx != 0 {
            candidates.append(Intersection(edge: .left, time: (rect.origin.x - p₀.x) / vector.dx))
            candidates.append(Intersection(edge: .right, time: (rect.maxX - p₀.x) / vector.dx))
        }

        // Vertical edges
        if vector.dy != 0 {
            candidates.append(Intersection(edge: .top, time: (rect.origin.y - p₀.y) / vector.dy))
            candidates.append(Intersection(edge: .bottom, time: (rect.maxY - p₀.y) / vector.dy))
        }

        return candidates
            .filter { $0.time >= 0 && $0.time <= 1 }
            .filter { rect.containsInclusive($0.point(on: self, within: rect)) }
            .sorted { $0.time < $1.time }
    }

}

/// Represents an intersection of a line segment with an axis-aligned rectangle
public struct Intersection {

    public enum Edge {
        case left
        case right
        case top
        case bottom
    }

    let edge: Edge
    let time: CGFloat

    func point(on segment: Ray, within rect: CGRect) -> CGPoint {
        let pt = segment.point(at: time)
        // Eliminate floating point imprecision based on the edge axis
        switch edge {
        case .left:
            return CGPoint(x: rect.origin.x, y: pt.y)
        case .right:
            return CGPoint(x: rect.maxX, y: pt.y)
        case .top:
            return CGPoint(x: pt.x, y: rect.origin.y)
        case .bottom:
            return CGPoint(x: pt.x, y: rect.maxY)
        }
    }

    func nearCorner(of rect: CGRect, along segment: Ray, thresh: CGFloat = 0.5) -> CGPoint? {
        let here = self.point(on: segment, within: rect)

        let closeToTop = abs(rect.origin.y - here.y) < thresh
        let closeToBottom = abs(rect.maxY - here.y) < thresh
        let closeToLeft = abs(rect.origin.x - here.x) < thresh
        let closeToRight = abs(rect.maxX - here.x) < thresh

        switch edge {
        case .left:
            if closeToTop {
                return rect.origin
            } else if closeToBottom {
                return CGPoint(x: rect.origin.x, y: rect.maxY)
            }
            return nil
        case .right:
            if closeToTop {
                return CGPoint(x: rect.maxX, y: rect.origin.y)
            } else if closeToBottom {
                return rect.antipodal
            }
            return nil
        case .top:
            if closeToLeft {
                return rect.origin
            } else if closeToRight {
                return CGPoint(x: rect.maxX, y: rect.origin.y)
            }
            return nil
        case .bottom:
            if closeToLeft {
                return CGPoint(x: rect.origin.x, y: rect.maxY)
            } else if closeToRight {
                return rect.antipodal
            }
            return nil
        }
    }

}

extension CGPoint {

    /// Translates a point by a vector.
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    /// Translates a point in place by a vector.
    static func += (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs + rhs
    }

    /// Translates a point by the inverse of a vector.
    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    /// Translates a point in place by the inverse of a vector.
    static func -= (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs - rhs
    }

    /// Computes the displacement vector from one point to another.
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }
}

extension CGVector {

    var magnitude: CGFloat {
        hypot(self.dx, self.dy)
    }

    /// Scale the vector by a constant
    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

}

extension CGRect {

    var antipodal: CGPoint {
        CGPoint(x: self.maxX, y: self.maxY)
    }

    /// Check if point is on rect border
    public func borderContains(point: CGPoint) -> Bool {
        if (point.x == self.origin.x || point.x == self.maxX) &&
           (self.origin.y <= point.y && point.y <= self.maxY) {
            return true
        }
        if (point.y == self.origin.y || point.y == self.maxY) &&
           (self.origin.x <= point.x && point.x <= self.maxX) {
            return true
        }
        return false
    }

    /// Check if the point is contained within the rectangle and its border
    public func containsInclusive(_ point: CGPoint) -> Bool {
        point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY
    }

}
