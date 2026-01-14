import Foundation

// MARK: - Thread-safe Data Accumulator

/// Thread-safe container for accumulating Data from concurrent sources
private final class DataAccumulator: @unchecked Sendable {
    private var data = Data()
    private let lock = NSLock()

    func append(_ newData: Data) {
        lock.lock()
        defer { lock.unlock() }
        data.append(newData)
    }

    var value: Data {
        lock.lock()
        defer { lock.unlock() }
        return data
    }
}

extension PortForwardProcessManager {
    /// Fetches all Kubernetes namespaces.
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

    /// Fetches services in a specific namespace.
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

    /// Executes a kubectl command and returns the output.
    nonisolated func executeKubectl(arguments: [String]) async throws -> String {
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

                // Thread-safe accumulators for concurrent data collection
                let outputAccumulator = DataAccumulator()
                let errorAccumulator = DataAccumulator()

                // Use autoreleasepool in handlers - background queues don't auto-drain
                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    autoreleasepool {
                        let data = handle.availableData
                        if !data.isEmpty {
                            outputAccumulator.append(data)
                        }
                    }
                }

                errorPipe.fileHandleForReading.readabilityHandler = { handle in
                    autoreleasepool {
                        let data = handle.availableData
                        if !data.isEmpty {
                            errorAccumulator.append(data)
                        }
                    }
                }

                do {
                    try process.run()
                    process.waitUntilExit()

                    outputPipe.fileHandleForReading.readabilityHandler = nil
                    errorPipe.fileHandleForReading.readabilityHandler = nil

                    // Use autoreleasepool for final reads
                    autoreleasepool {
                        let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        outputAccumulator.append(remainingOutput)
                        errorAccumulator.append(remainingError)
                    }

                    let output = String(data: outputAccumulator.value, encoding: .utf8) ?? ""
                    let errorOutput = String(data: errorAccumulator.value, encoding: .utf8) ?? ""

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
