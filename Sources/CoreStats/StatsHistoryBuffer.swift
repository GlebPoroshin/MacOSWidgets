import Foundation

public struct StatsHistoryBuffer<Element: Sendable>: Sendable {
    private var storage: [Element]
    private var startIndex: Int
    public private(set) var count: Int
    public let capacity: Int

    public init(capacity: Int) {
        self.capacity = max(capacity, 1)
        self.storage = []
        self.startIndex = 0
        self.count = 0
    }

    public var isEmpty: Bool { count == 0 }

    public mutating func append(_ element: Element) {
        if storage.count < capacity {
            storage.append(element)
            count = min(count + 1, capacity)
        } else {
            let index = (startIndex + count) % capacity
            storage[index] = element
            startIndex = (startIndex + 1) % capacity
            count = capacity
        }
    }

    public func valuesOldestFirst() -> [Element] {
        guard count > 0 else { return [] }
        var result: [Element] = []
        result.reserveCapacity(count)
        for offset in 0..<count {
            let index = (startIndex + offset) % capacity
            result.append(storage[index])
        }
        return result
    }

    public func valuesNewestFirst() -> [Element] {
        valuesOldestFirst().reversed()
    }
}
