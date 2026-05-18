import CoreBluetooth
import Foundation

let batteryServiceUUID = CBUUID(string: "180F")
let batteryLevelUUID = CBUUID(string: "2A19")
let userDescriptionUUID = CBUUID(string: "2901")

// Read target UUID from first argument, or use saved keyboard
func getTargetUUID() -> UUID? {
    if CommandLine.arguments.count > 1 {
        return UUID(uuidString: CommandLine.arguments[1])
    }
    // Read from zmk-battery-bar preferences
    if let uuid = UserDefaults(suiteName: "com.zmk-battery-bar.app")?.string(forKey: "selectedKeyboardUUID") {
        return UUID(uuidString: uuid)
    }
    return nil
}

class BLEReader: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let targetUUID: UUID
    var central: CBCentralManager!
    var peripheral: CBPeripheral?
    var characteristics: [CBCharacteristic] = []
    var roles: [CBCharacteristic: String] = [:]
    var levels: [CBCharacteristic: Int] = [:]
    var pendingDescriptors: Set<CBCharacteristic> = []

    init(uuid: UUID) {
        self.targetUUID = uuid
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        guard c.state == .poweredOn else {
            print("error:bluetooth_off")
            exit(1)
        }
        let ps = c.retrievePeripherals(withIdentifiers: [targetUUID])
        guard let p = ps.first else {
            print("error:not_found")
            exit(1)
        }
        peripheral = p
        p.delegate = self
        c.connect(p)

        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            // Timeout - output whatever we have
            self.outputResults()
        }
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        p.discoverServices([batteryServiceUUID])
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        print("error:connect_failed")
        exit(1)
    }

    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = p.services else { return }
        for s in services {
            p.discoverCharacteristics([batteryLevelUUID], for: s)
        }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for c in chars {
            characteristics.append(c)
            pendingDescriptors.insert(c)
            p.discoverDescriptors(for: c)
            p.readValue(for: c)
        }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let desc = characteristic.descriptors?.first(where: { $0.uuid == userDescriptionUUID }) {
            p.readValue(for: desc)
        } else {
            pendingDescriptors.remove(characteristic)
            checkComplete()
        }
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        guard descriptor.uuid == userDescriptionUUID,
              let characteristic = descriptor.characteristic else { return }

        if let str = descriptor.value as? String {
            let lower = str.lowercased()
            if lower.contains("central") || lower.contains("left") {
                roles[characteristic] = "central"
            } else if lower.contains("peripheral") || lower.contains("right") {
                roles[characteristic] = "peripheral"
            }
        }
        pendingDescriptors.remove(characteristic)
        checkComplete()
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let level = data.first {
            levels[characteristic] = Int(level)
        }
        checkComplete()
    }

    func checkComplete() {
        guard pendingDescriptors.isEmpty,
              levels.count >= characteristics.count else { return }
        outputResults()
    }

    func outputResults() {
        // Assign fallback roles by index if descriptors didn't provide them
        if roles.isEmpty && characteristics.count >= 2 {
            roles[characteristics[0]] = "central"
            roles[characteristics[1]] = "peripheral"
        } else if roles.isEmpty && characteristics.count == 1 {
            roles[characteristics[0]] = "central"
        }

        var centralLevel: String = "--"
        var peripheralLevel: String = "--"

        for c in characteristics {
            if let level = levels[c] {
                switch roles[c] {
                case "central":
                    centralLevel = String(level)
                case "peripheral":
                    peripheralLevel = String(level)
                default:
                    if centralLevel == "--" {
                        centralLevel = String(level)
                    } else {
                        peripheralLevel = String(level)
                    }
                }
            }
        }

        // Output: central,peripheral
        print("\(centralLevel),\(peripheralLevel)")
        exit(0)
    }
}

guard let uuid = getTargetUUID() else {
    print("error:no_uuid")
    exit(1)
}
let reader = BLEReader(uuid: uuid)
RunLoop.main.run()
