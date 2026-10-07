import Foundation
import Network
import SwiftData
#if os(iOS)
import UIKit
#endif

@Observable
final class WiFiSyncService {
    var isServerRunning = false
    var isSearching = false
    var statusMessage = "Готов к синхронизации"
    var connectedDevices: [NWEndpoint] = []
    
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var connection: NWConnection?
    
    private let serviceType = "_fapsync._tcp"
    private let domain = "local."
    
    private var deviceName: String {
        #if os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        return UIDevice.current.name
        #endif
    }
    
    // Безопасное имя сервиса без спецсимволов для Bonjour
    private var safeServiceName: String {
        let name = deviceName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
        return name.isEmpty ? "Device" : name
    }
    
    private func createParameters() -> NWParameters {
        let tcpOptions = NWProtocolTCP.Options()
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        return parameters
    }
    
    // Запуск сервера на приём данных
    func startServer(onReceiveData: @escaping (Data) -> Void) {
        stopAll() // Сброс прошлых соединений
        
        do {
            let parameters = createParameters()
            listener = try NWListener(using: parameters)
            
            // Регистрируем имя сервиса в формате Bonjour
            listener?.service = NWListener.Service(name: "FAP-\(safeServiceName)", type: serviceType)
            
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        self.isServerRunning = true
                        self.statusMessage = "Сервер запущен. Ожидание..."
                    case .failed(let error):
                        self.isServerRunning = false
                        if error.localizedDescription.contains("65555") || error.localizedDescription.contains("NoAuth") {
                            self.statusMessage = "Ошибка авторизации локальной сети. Проверьте Info.plist и настройки iPad."
                        } else {
                            self.statusMessage = "Ошибка: \(error.localizedDescription)"
                        }
                    default: break
                    }
                }
            }
            
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.connection = newConnection
                newConnection.start(queue: .main)
                self?.receiveData(on: newConnection, completion: onReceiveData)
            }
            
            listener?.start(queue: .main)
        } catch {
            statusMessage = "Ошибка запуска сервера: \(error.localizedDescription)"
        }
    }
    
    // Поиск устройств в локальной сети Wi-Fi
    func startBrowsing() {
        let parameters = createParameters()
        let browserDescriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: domain)
        browser = NWBrowser(for: browserDescriptor, using: parameters)
        
        browser?.browseResultsChangedHandler = { [weak self] results, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.connectedDevices = results.map { $0.endpoint }
                if results.isEmpty {
                    self.statusMessage = "Поиск устройств в сети Wi-Fi..."
                } else {
                    self.statusMessage = "Найдено устройств: \(results.count)"
                }
            }
        }
        
        browser?.start(queue: .main)
        isSearching = true
    }
    
    // Отправка данных на выбранное устройство
    func sendData(_ data: Data, to endpoint: NWEndpoint, completion: @escaping (Bool) -> Void) {
        let parameters = createParameters()
        let connection = NWConnection(to: endpoint, using: parameters)
        connection.start(queue: .main)
        
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                var chunkSize = UInt32(data.count).bigEndian
                let sizeData = Data(bytes: &chunkSize, count: MemoryLayout<UInt32>.size)
                
                connection.send(content: sizeData, completion: .contentProcessed({ error in
                    if let error = error {
                        print("Ошибка передачи размера: \(error)")
                        completion(false)
                        return
                    }
                    connection.send(content: data, completion: .contentProcessed({ err in
                        if err == nil {
                            DispatchQueue.main.async {
                                self?.statusMessage = "Данные отправлены!"
                            }
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }))
                }))
            }
        }
    }
    
    private func receiveData(on connection: NWConnection, completion: @escaping (Data) -> Void) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { sizeData, _, _, error in
            guard let sizeData = sizeData, sizeData.count == 4 else { return }
            let size = sizeData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            connection.receive(minimumIncompleteLength: Int(size), maximumLength: Int(size)) { payloadData, _, _, _ in
                if let payloadData = payloadData {
                    DispatchQueue.main.async {
                        completion(payloadData)
                    }
                }
            }
        }
    }
    
    func stopAll() {
        listener?.cancel()
        browser?.cancel()
        connection?.cancel()
        listener = nil
        browser = nil
        connection = nil
        isServerRunning = false
        isSearching = false
    }
}
