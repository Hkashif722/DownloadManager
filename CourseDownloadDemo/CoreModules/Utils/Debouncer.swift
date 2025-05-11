// Utils/Debouncer.swift
import Foundation

class Debouncer {
    private let timeInterval: TimeInterval
    private var timer: Timer?
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }
    
    func debounce(action: @escaping () -> Void) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            action()
        }
    }
    
    func cancel() {
        timer?.invalidate()
        timer = nil
    }
}