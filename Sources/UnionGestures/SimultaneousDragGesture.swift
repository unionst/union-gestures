//
//  SimultaneousDragGesture.swift
//  union-gestures
//
//  Created by Aaron Moss on 9/10/25.
//

import SwiftUI

public struct SimultaneousDragGesture: UIGestureRecognizerRepresentable {
    public struct Value : Equatable, Sendable {
        public var time: Date
        public var location: CGPoint
        public var startLocation: CGPoint

        public var translation: CGSize {
            CGSize(width: location.x - startLocation.x, height: location.y - startLocation.y)
        }

        public static func == (a: SimultaneousDragGesture.Value, b: SimultaneousDragGesture.Value) -> Bool {
            a.time == b.time && a.location == b.location && a.startLocation == b.startLocation
        }
    }

    public var allowsSwipeToDismiss: Bool = false
    var onBegan: (() -> Void)?
    var onChanged: ((Value) -> Void)?
    var onEnded: ((Value) -> Void)?

    public init(allowsSwipeToDismiss: Bool = false) {
        self.allowsSwipeToDismiss = allowsSwipeToDismiss
    }

    public func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let dragGesture = UILongPressGestureRecognizer()

        dragGesture.minimumPressDuration = 0.0
        dragGesture.allowableMovement = CGFloat.greatestFiniteMagnitude
        dragGesture.delegate = context.coordinator

        return dragGesture
    }

    public func handleUIGestureRecognizerAction(_ gestureRecognizer: UILongPressGestureRecognizer, context: Context) {
        guard gestureRecognizer.view?.window != nil else {
            context.coordinator.reset()
            return
        }

        switch gestureRecognizer.state {
        case .began:
            context.coordinator.start = safeLocation(from: context)
            context.coordinator.startTime = Date()
            context.coordinator.hasCheckedSwipe = false
            onBegan?()
            onChanged?(safeValue(from: context))
        case .changed:
            if context.coordinator.allowsSwipeToDismiss && !context.coordinator.hasCheckedSwipe {
                if let startTime = context.coordinator.startTime,
                   Date().timeIntervalSince(startTime) < 0.1 {
                    let val = safeValue(from: context)
                    let deltaY = val.translation.height
                    let deltaX = abs(val.translation.width)

                    if deltaY > 20 && deltaY > deltaX * 1.5 {
                        gestureRecognizer.isEnabled = false
                        gestureRecognizer.isEnabled = true
                        context.coordinator.reset()
                        return
                    }
                } else {
                    context.coordinator.hasCheckedSwipe = true
                }
            }
            onChanged?(safeValue(from: context))
        case .ended, .cancelled:
            onEnded?(safeValue(from: context))
            context.coordinator.reset()
        default:
            break
        }
    }

    func value(from context: Context) -> Value {
        let location = context.converter.location(in: .local)
        let start = context.coordinator.start ?? location
        let time = Date()

        return .init(time: time, location: location, startLocation: start)
    }

    func safeLocation(from context: Context) -> CGPoint {
        context.converter.location(in: .local)
    }

    func safeValue(from context: Context) -> Value {
        let location = safeLocation(from: context)
        let start = context.coordinator.start ?? location
        let time = Date()
        return .init(time: time, location: location, startLocation: start)
    }

    public func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        .init(allowsSwipeToDismiss: allowsSwipeToDismiss)
    }

    public class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var start: CGPoint?
        var allowsSwipeToDismiss: Bool
        var startTime: Date?
        var hasCheckedSwipe = false

        init(allowsSwipeToDismiss: Bool = false) {
            self.allowsSwipeToDismiss = allowsSwipeToDismiss
            super.init()
        }

        func reset() {
            start = nil
            startTime = nil
            hasCheckedSwipe = false
        }

        public func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}

extension SimultaneousDragGesture {

    @MainActor @preconcurrency public func onBegan(perform action: @escaping () -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.onBegan = action
        return mutableSelf
    }

    @MainActor @preconcurrency public func onChanged(
        perform action: @escaping (SimultaneousDragGesture.Value) -> Void
    ) -> Self {
        var mutableSelf = self
        mutableSelf.onChanged = action
        return mutableSelf
    }

    @MainActor @preconcurrency public func onEnded(
        perform action: @escaping (SimultaneousDragGesture.Value) -> Void
    ) -> Self {
        var mutableSelf = self
        mutableSelf.onEnded = action
        return mutableSelf
    }
}
