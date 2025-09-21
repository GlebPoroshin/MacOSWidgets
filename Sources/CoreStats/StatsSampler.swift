import Foundation
import Darwin
import Darwin.Mach

public actor StatsSampler {
    public struct Configuration: Sendable {
        public var sampleInterval: TimeInterval
        public var historyWindow: TimeInterval

        public init(sampleInterval: TimeInterval = 5.0, historyWindow: TimeInterval = 180.0) {
            self.sampleInterval = sampleInterval
            self.historyWindow = max(historyWindow, sampleInterval)
        }
    }

    public enum Error: Swift.Error, Sendable {
        case machError(kern_return_t)
        case cpuInfoUnavailable
        case appGroupUnavailable
    }

    private struct CPULoad: Sendable {
        var user: UInt32
        var system: UInt32
        var idle: UInt32
        var nice: UInt32

        init(info: host_cpu_load_info) {
            user = info.cpu_ticks.0
            system = info.cpu_ticks.1
            idle = info.cpu_ticks.2
            nice = info.cpu_ticks.3
        }
    }

    private var configuration: Configuration
    private var previousLoads: [CPULoad]?
    private var cpuHistory: StatsHistoryBuffer<Double>
    private var memoryHistory: StatsHistoryBuffer<Double>

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        let capacity = StatsSampler.historyCapacity(for: configuration)
        self.cpuHistory = StatsHistoryBuffer(capacity: capacity)
        self.memoryHistory = StatsHistoryBuffer(capacity: capacity)
    }

    public func seed(with snapshot: StatsSnapshot) {
        let capacity = StatsSampler.historyCapacity(for: configuration)
        cpuHistory = StatsHistoryBuffer(capacity: capacity)
        memoryHistory = StatsHistoryBuffer(capacity: capacity)

        for value in snapshot.history.cpu.suffix(capacity) {
            cpuHistory.append(value)
        }

        for value in snapshot.history.memory.suffix(capacity) {
            memoryHistory.append(value)
        }
    }

    public func updateConfiguration(_ newValue: Configuration) {
        configuration = newValue
        let capacity = StatsSampler.historyCapacity(for: newValue)
        cpuHistory = StatsHistoryBuffer(capacity: capacity)
        memoryHistory = StatsHistoryBuffer(capacity: capacity)
        previousLoads = nil
    }

    public func takeSnapshot() throws -> StatsSnapshot {
        let (cpu, perCore) = try computeCPUUsage()
        let memory = try computeMemoryUsage()
        let uptime = ProcessInfo.processInfo.systemUptime

        cpuHistory.append(cpu)
        let memoryUsageRatio = memory.totalBytes > 0 ? Double(memory.usedBytes) / Double(memory.totalBytes) : 0
        memoryHistory.append(memoryUsageRatio)

        let historyWindow = configuration.historyWindow
        let history = StatsSnapshot.History(
            cpu: cpuHistory.valuesOldestFirst(),
            memory: memoryHistory.valuesOldestFirst(),
            windowSec: historyWindow
        )

        return StatsSnapshot(
            version: StatsSnapshot.schemaVersion,
            timestamp: Date(),
            cpu: .init(total: cpu, perCore: perCore),
            memory: .init(usedBytes: memory.usedBytes,
                          totalBytes: memory.totalBytes,
                          swapUsedBytes: memory.swapUsedBytes),
            uptime: uptime,
            history: history
        )
    }

    private func computeCPUUsage() throws -> (Double, [Double]) {
        var cpuInfo: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0
        var processorCount: natural_t = 0

        let hostPort: mach_port_t = mach_host_self()
        let taskPort: mach_port_t = mach_port_t(task_self_trap())
        let result = host_processor_info(hostPort,
                                         PROCESSOR_CPU_LOAD_INFO,
                                         &processorCount,
                                         &cpuInfo,
                                         &cpuInfoCount)
        guard result == KERN_SUCCESS, let cpuInfo else {
            if let cpuInfo {
                vm_deallocate(taskPort, vm_address_t(bitPattern: cpuInfo), vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
            }
            throw Error.cpuInfoUnavailable
        }

        defer {
            vm_deallocate(taskPort, vm_address_t(bitPattern: cpuInfo), vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        let coreCount = Int(processorCount)
        let loadInfos: [host_cpu_load_info] = cpuInfo.withMemoryRebound(to: host_cpu_load_info.self, capacity: coreCount) {
            var buffer: [host_cpu_load_info] = []
            buffer.reserveCapacity(coreCount)
            for index in 0..<coreCount {
                buffer.append($0[index])
            }
            return buffer
        }

        if previousLoads?.count != coreCount {
            previousLoads = loadInfos.map(CPULoad.init)
            return (0, Array(repeating: 0, count: coreCount))
        }

        guard let previousLoads else {
            throw Error.cpuInfoUnavailable
        }

        var totalBusy: Double = 0
        var totalTicks: Double = 0
        var perCoreUsage: [Double] = []
        perCoreUsage.reserveCapacity(coreCount)

        for index in 0..<coreCount {
            let current = CPULoad(info: loadInfos[index])
            let previous = previousLoads[index]

            let user = Double(current.user &- previous.user)
            let system = Double(current.system &- previous.system)
            let nice = Double(current.nice &- previous.nice)
            let idle = Double(current.idle &- previous.idle)

            let busy = max(0, user + system + nice)
            let ticks = busy + max(0, idle)
            let usage = ticks > 0 ? busy / ticks : 0
            perCoreUsage.append(min(max(usage, 0), 1))
            totalBusy += busy
            totalTicks += ticks
        }

        self.previousLoads = loadInfos.map(CPULoad.init)
        let totalUsage = totalTicks > 0 ? totalBusy / totalTicks : 0
        return (min(max(totalUsage, 0), 1), perCoreUsage)
    }

    private struct MemoryUsage {
        var usedBytes: UInt64
        var totalBytes: UInt64
        var swapUsedBytes: UInt64
    }

    private func computeMemoryUsage() throws -> MemoryUsage {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        var vmStats = vm_statistics64()
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        guard result == KERN_SUCCESS else {
            throw Error.machError(result)
        }

        var pageSize: vm_size_t = 0
        let pageResult = host_page_size(hostPort, &pageSize)
        if pageResult != KERN_SUCCESS || pageSize == 0 {
            pageSize = vm_size_t(4096)
        }
        let active = UInt64(vmStats.active_count) * UInt64(pageSize)
        let wired = UInt64(vmStats.wire_count) * UInt64(pageSize)
        let compressed = UInt64(vmStats.compressor_page_count) * UInt64(pageSize)
        let speculative = UInt64(vmStats.speculative_count) * UInt64(pageSize)
        let purgeable = UInt64(vmStats.purgeable_count) * UInt64(pageSize)
        let external = UInt64(vmStats.external_page_count) * UInt64(pageSize)

        let used = active + wired + compressed + speculative + external - purgeable
        let total = ProcessInfo.processInfo.physicalMemory

        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.stride
        let swapResult = sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0)
        let swapUsed = swapResult == 0 ? UInt64(swapUsage.xsu_used) : 0

        return MemoryUsage(usedBytes: min(used, total), totalBytes: total, swapUsedBytes: swapUsed)
    }

    private static func historyCapacity(for configuration: Configuration) -> Int {
        max(1, Int(round(configuration.historyWindow / max(configuration.sampleInterval, 0.5))))
    }
}
