import Foundation
import Darwin

// MARK: - Process Manager Actor

actor PortForwardProcessManager {
    private var processes: [UUID: [PortForwardProcessType: Process]] = [:]
    private var outputTasks: [UUID: [PortForwardProcessType: Task<Void, Never>]] = [:]
    private var connectionErrors: [UUID: Date] = [:]
    private var logHandlers: [UUID: LogHandler] = [:]
    private var portConflictHandlers: [UUID: PortConflictHandler] = [:]

    // MARK: - Handler Management

    func setLogHandler(for id: UUID, handler: @escaping LogHandler) {
        logHandlers[id] = handler
    }

    func removeLogHandler(for id: UUID) {
        logHandlers.removeValue(forKey: id)
    }

    func setPortConflictHandler(for id: UUID, handler: @escaping PortConflictHandler) {
        portConflictHandlers[id] = handler
    }

    func removePortConflictHandler(for id: UUID) {
        portConflictHandlers.removeValue(forKey: id)
    }

    // MARK: - Port Forward

    func startPortForward(
        id: UUID,
        namespace: String,
        service: String,
        localPort: Int,
        remotePort: Int
    ) async throws -> Process {
        guard let kubectlPath = DependencyChecker.shared.kubectlPath else {
            throw KubectlError.kubectlNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: kubectlPath)
        process.arguments = [
            "port-forward",
            "-n", namespace,
            "svc/\(service)",
            "\(localPort):\(remotePort)",
            "--address=127.0.0.1"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if processes[id] == nil {
            processes[id] = [:]
        }
        processes[id]?[.portForward] = process

        startReadingOutput(pipe: pipe, id: id, type: .portForward)

        return process
    }

    // MARK: - Standard Proxy

    func startProxy(
        id: UUID,
        externalPort: Int,
        internalPort: Int
    ) async throws -> Process {
        guard let socatPath = DependencyChecker.shared.socatPath else {
            throw KubectlError.executionFailed("socat not found")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: socatPath)
        process.arguments = [
            "TCP-LISTEN:\(externalPort),fork,reuseaddr",
            "TCP:127.0.0.1:\(internalPort)"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if processes[id] == nil {
            processes[id] = [:]
        }
        processes[id]?[.proxy] = process

        startReadingOutput(pipe: pipe, id: id, type: .proxy)

        return process
    }

    // MARK: - Direct Exec Proxy (Multi-Connection)

    func startDirectExecProxy(
        id: UUID,
        namespace: String,
        service: String,
        externalPort: Int,
        remotePort: Int
    ) async throws -> Process {
        guard let kubectlPath = DependencyChecker.shared.kubectlPath else {
            throw KubectlError.kubectlNotFound
        }

        guard let socatPath = DependencyChecker.shared.socatPath else {
            throw KubectlError.executionFailed("socat not found for multi-connection mode")
        }

        let wrapperScript = createWrapperScript(
            kubectlPath: kubectlPath,
            socatPath: socatPath,
            namespace: namespace,
            service: service,
            remotePort: remotePort
        )

        let scriptPath = "/tmp/pf-wrapper-\(id.uuidString).sh"
        try wrapperScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", scriptPath]
        try chmod.run()
        chmod.waitUntilExit()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: socatPath)
        process.arguments = [
            "TCP-LISTEN:\(externalPort),fork,reuseaddr",
            "EXEC:\(scriptPath)"
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        if processes[id] == nil {
            processes[id] = [:]
        }
        processes[id]?[.proxy] = process

        startReadingOutput(pipe: pipe, id: id, type: .proxy)

        return process
    }

    private func createWrapperScript(
        kubectlPath: String,
        socatPath: String,
        namespace: String,
        service: String,
        remotePort: Int
    ) -> String {
        """
        #!/bin/bash
        PORT=$((30000 + ($$ % 30000)))
        while /usr/bin/nc -z 127.0.0.1 $PORT 2>/dev/null; do
            PORT=$((PORT + 1))
        done
        \(kubectlPath) port-forward -n \(namespace) svc/\(service) $PORT:\(remotePort) --address=127.0.0.1 >/dev/null 2>&1 &
        KPID=$!
        trap "kill $KPID 2>/dev/null" EXIT
        for i in 1 2 3 4 5 6 7 8 9 10; do
            if /usr/bin/nc -z 127.0.0.1 $PORT 2>/dev/null; then break; fi
            sleep 0.5
        done
        \(socatPath) - TCP:127.0.0.1:$PORT
        """
    }

    // MARK: - Output Reading

    private func startReadingOutput(pipe: Pipe, id: UUID, type: PortForwardProcessType) {
        let task = Task { [weak self] in
            let handle = pipe.fileHandleForReading

            while true {
                let data = handle.availableData
                if data.isEmpty { break }

                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                    let lines = output.components(separatedBy: .newlines)
                    for line in lines where !line.isEmpty {
                        let isError = PortForwardOutputParser.isErrorLine(line)

                        if isError {
                            await self?.markConnectionError(id: id)
                        }

                        if let port = PortForwardOutputParser.detectPortConflict(in: line) {
                            if let handler = await self?.portConflictHandlers[id] {
                                handler(port)
                            }
                        }

                        if let handler = await self?.logHandlers[id] {
                            handler(line, type, isError)
                        }
                    }
                }
            }
        }

        if outputTasks[id] == nil {
            outputTasks[id] = [:]
        }
        outputTasks[id]?[type] = task
    }

    // MARK: - Port Conflict Resolution

    func killProcessOnPort(_ port: Int) async {
        let lsof = Process()
        lsof.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        lsof.arguments = ["-ti", "tcp:\(port)"]

        let pipe = Pipe()
        lsof.standardOutput = pipe
        lsof.standardError = FileHandle.nullDevice

        do {
            try lsof.run()
            lsof.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                let pids = output.components(separatedBy: .newlines)
                for pidStr in pids {
                    if let pid = Int32(pidStr.trimmingCharacters(in: .whitespaces)) {
                        kill(pid, SIGTERM)
                    }
                }

                try? await Task.sleep(for: .milliseconds(300))

                for pidStr in pids {
                    if let pid = Int32(pidStr.trimmingCharacters(in: .whitespaces)) {
                        if kill(pid, 0) == 0 {
                            kill(pid, SIGKILL)
                        }
                    }
                }
            }
        } catch {
            // Ignore errors
        }
    }

    // MARK: - Error Tracking

    private func markConnectionError(id: UUID) {
        connectionErrors[id] = Date()
    }

    func hasRecentError(for id: UUID, within seconds: TimeInterval = 10) -> Bool {
        guard let errorTime = connectionErrors[id] else { return false }
        return Date().timeIntervalSince(errorTime) < seconds
    }

    func clearError(for id: UUID) {
        connectionErrors.removeValue(forKey: id)
    }

    // MARK: - Process Lifecycle

    func killProcesses(for id: UUID) {
        if let tasks = outputTasks[id] {
            for (_, task) in tasks {
                task.cancel()
            }
        }
        outputTasks[id] = nil

        guard let procs = processes[id] else { return }

        for (_, process) in procs {
            if process.isRunning {
                process.terminate()
            }
        }
        processes[id] = nil

        let scriptPath = "/tmp/pf-wrapper-\(id.uuidString).sh"
        try? FileManager.default.removeItem(atPath: scriptPath)
    }

    func isProcessRunning(for id: UUID, type: PortForwardProcessType) -> Bool {
        processes[id]?[type]?.isRunning ?? false
    }

    func isPortOpen(port: Int) -> Bool {
        PortHealthChecker.isPortOpen(port: port)
    }

    func killAllPortForwarderProcesses() async {
        let pkillKubectl = Process()
        pkillKubectl.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pkillKubectl.arguments = ["-9", "-f", "kubectl.*port-forward"]
        try? pkillKubectl.run()
        pkillKubectl.waitUntilExit()

        let pkillSocat = Process()
        pkillSocat.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pkillSocat.arguments = ["-9", "-f", "socat.*TCP-LISTEN"]
        try? pkillSocat.run()
        pkillSocat.waitUntilExit()

        try? await Task.sleep(for: .milliseconds(500))

        processes.removeAll()
        for (_, tasks) in outputTasks {
            for (_, task) in tasks { task.cancel() }
        }
        outputTasks.removeAll()
    }

    // MARK: - Kubernetes Discovery

    func fetchNamespaces() async throws -> [KubernetesNamespace] {
        let output = try await executeKubectl(arguments: ["get", "namespaces", "-o", "json"])

        do {
            let response = try JSONDecoder().decode(
                KubernetesNamespace.ListResponse.self,
                from: Data(output.utf8)
            )
            let namespaces = KubernetesNamespace.from(response: response)
            return namespaces.sorted { $0.name < $1.name }
        } catch {
            throw KubectlError.parsingFailed(error.localizedDescription)
        }
    }

    func fetchServices(namespace: String) async throws -> [KubernetesService] {
        let output = try await executeKubectl(arguments: ["get", "services", "-n", namespace, "-o", "json"])

        do {
            let response = try JSONDecoder().decode(
                KubernetesService.ListResponse.self,
                from: Data(output.utf8)
            )
            let services = KubernetesService.from(response: response)
            return services.sorted { $0.name < $1.name }
        } catch {
            throw KubectlError.parsingFailed(error.localizedDescription)
        }
    }

    private nonisolated func executeKubectl(arguments: [String]) async throws -> String {
        guard let kubectlPath = DependencyChecker.shared.kubectlPath else {
            throw KubectlError.kubectlNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: kubectlPath)
                process.arguments = arguments

                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe

                // Collect output data asynchronously to avoid pipe buffer deadlock
                var outputData = Data()
                var errorData = Data()
                let outputQueue = DispatchQueue(label: "kubectl.output")
                let errorQueue = DispatchQueue(label: "kubectl.error")

                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        outputQueue.sync { outputData.append(data) }
                    }
                }

                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if !data.isEmpty {
                        errorQueue.sync { errorData.append(data) }
                    }
                }

                do {
                    try process.run()
                    process.waitUntilExit()

                    // Stop reading handlers
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    // Read any remaining data
                    let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    outputQueue.sync { outputData.append(remainingOutput) }
                    errorQueue.sync { errorData.append(remainingError) }

                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                    if process.terminationStatus != 0 {
                        if errorOutput.contains("Unable to connect") ||
                           errorOutput.contains("connection refused") ||
                           errorOutput.contains("no configuration") ||
                           errorOutput.contains("dial tcp") {
                            continuation.resume(throwing: KubectlError.clusterNotConnected)
                        } else {
                            continuation.resume(throwing: KubectlError.executionFailed(
                                errorOutput.isEmpty ? "Unknown error" : errorOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                            ))
                        }
                    } else {
                        continuation.resume(returning: output)
                    }
                } catch {
                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
