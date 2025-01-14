/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import CoreBluetooth

internal enum SecureDFUOpCode : UInt8 {
    case getProtocolVersion   = 0x0  // not supported by this library
    case createObject         = 0x01
    case setPRNValue          = 0x02
    case calculateChecksum    = 0x03
    case execute              = 0x04
 // case no-such-op-code      = 0x05
    case selectObject         = 0x06
    case getMtu               = 0x07 // not supported by this library
    case write                = 0x08 // not supported by this library
    case ping                 = 0x09 // not supported by this library
    case getHwVersion         = 0x0A // not supported by this library
    case getFwVersion         = 0x0B // not supported by this library
    case abort                = 0x0C
    case responseCode         = 0x60

    var code: UInt8 {
        return rawValue
    }
}

internal enum SecureDFUExtendedErrorCode : UInt8 {
    case noError              = 0x00
    case wrongCommandFormat   = 0x02
    case unknownCommand       = 0x03
    case initCommandInvalid   = 0x04
    case fwVersionFailure     = 0x05
    case hwVersionFailure     = 0x06
    case sdVersionFailure     = 0x07
    case signatureMissing     = 0x08
    case wrongHashType        = 0x09
    case hashFailed           = 0x0A
    case wrongSignatureType   = 0x0B
    case verificationFailed   = 0x0C
    case insufficientSpace    = 0x0D
    
    // Note: When more result codes are added, the corresponding DFUError
    //       case needs to be added. See `error` property below.
    
    var code: UInt8 {
        return rawValue
    }
    
    var error: DFUError {
        return DFURemoteError.secureExtended.with(code: code)
    }
    
    var description: String {
        switch self {
        case .noError:              return "No error"
        case .wrongCommandFormat:   return "Wrong command format"
        case .unknownCommand:       return "Unknown command"
        case .initCommandInvalid:   return "Init command was invalid"
        case .fwVersionFailure:     return "FW version check failed"
        case .hwVersionFailure:     return "HW version check failed"
        case .sdVersionFailure:     return "SD version check failed"
        case .signatureMissing:     return "Signature missing"
        case .wrongHashType:        return "Invalid hash type"
        case .hashFailed:           return "Hashing failed"
        case .wrongSignatureType:   return "Invalid signature type"
        case .verificationFailed:   return "Verification failed"
        case .insufficientSpace:    return "Insufficient space for upgrade"
        }
    }
    
}

internal enum SecureDFUProcedureType : UInt8 {
    case command = 0x01
    case data    = 0x02
    
    var description: String{
        switch self{
            case .command:  return "Command"
            case .data:     return "Data"
        }
    }
}

internal enum SecureDFUImageType : UInt8 {
    case softdevice  = 0x00
    case application = 0x01
    case bootloader  = 0x02
    
    var description: String{
        switch self{
            case .softdevice:  return "Soft Device"
            case .application: return "Application"
            case .bootloader:  return "Bootloader"
        }
    }
}

internal enum SecureDFURequest {
    case getProtocolVersion
    case createCommandObject(withSize: UInt32)
    case createDataObject(withSize: UInt32)
    case selectCommandObject
    case selectDataObject
    case setPacketReceiptNotification(value: UInt16)
    case calculateChecksumCommand
    case executeCommand
    case getMtu
    case write(bytes: Data)
    case ping(id: UInt8)
    case getHwVersion
    case getFwVersion(image: SecureDFUImageType)
    case abort

    var data: Data {
        switch self {
        case .getProtocolVersion:
            return Data([SecureDFUOpCode.getProtocolVersion.code])
        case .createDataObject(let size):
            var data = Data([SecureDFUOpCode.createObject.code, SecureDFUProcedureType.data.rawValue])
            data += size.littleEndian
            return data
        case .createCommandObject(let size):
            var data = Data([SecureDFUOpCode.createObject.code, SecureDFUProcedureType.command.rawValue])
            data += size.littleEndian
            return data
        case .setPacketReceiptNotification(let size):
            var data = Data([SecureDFUOpCode.setPRNValue.code])
            data += size.littleEndian
            return data
        case .calculateChecksumCommand:
            return Data([SecureDFUOpCode.calculateChecksum.code])
        case .executeCommand:
            return Data([SecureDFUOpCode.execute.code])
        case .selectCommandObject:
            return Data([SecureDFUOpCode.selectObject.code, SecureDFUProcedureType.command.rawValue])
        case .selectDataObject:
            return Data([SecureDFUOpCode.selectObject.code, SecureDFUProcedureType.data.rawValue])
        case .getMtu:
            return Data([SecureDFUOpCode.getMtu.code])
        case .write(let bytes):
            var data = Data([SecureDFUOpCode.write.code])
            data += bytes
            data += UInt16(bytes.count).littleEndian
            return data
        case .ping(let id):
            return Data([SecureDFUOpCode.ping.code, id])
        case .getHwVersion:
            return Data([SecureDFUOpCode.getHwVersion.code])
        case .getFwVersion(let image):
            return Data([SecureDFUOpCode.getFwVersion.code, image.rawValue])
        case .abort:
            return Data([SecureDFUOpCode.abort.code])
        }
    }

    var description: String {
        switch self {
        case .getProtocolVersion:            return "Get Protocol Version (Op Code = 0)"
        case .createCommandObject(let size): return "Create Command Object (Op Code = 1, Type = 1, Size: \(size)b)"
        case .createDataObject(let size):    return "Create Data Object (Op Code = 1, Type = 2, Size: \(size)b)"
        case .setPacketReceiptNotification(let number):
                                             return "Packet Receipt Notif Req (Op Code = 2, Value = \(number))"
        case .calculateChecksumCommand:      return "Calculate Checksum (Op Code = 3)"
        case .executeCommand:                return "Execute Object (Op Code = 4)"
        case .selectCommandObject:           return "Select Command Object (Op Code = 6, Type = 1)"
        case .selectDataObject:              return "Select Data Object (Op Code = 6, Type = 2)"
        case .getMtu:                        return "Get MTU (Op Code = 7)"
        case .write(let bytes):              return "Write (Op Code = 8, Data = 0x\(bytes.hexString), Length = \(bytes.count))"
        case .ping(let id):                  return "Ping (Op Code = 9, ID = \(id))"
        case .getHwVersion:                  return "Get HW Version (Op Code = 10)"
        case .getFwVersion(let image):       return "Get FW Version (Op Code = 11, Type = \(image.rawValue))"
        case .abort:                         return "Abort (Op Code = 12)"
        }
    }
}

internal enum SecureDFUResultCode : UInt8 {
    case invalidCode           = 0x0
    case success               = 0x01
    case opCodeNotSupported    = 0x02
    case invalidParameter      = 0x03
    case insufficientResources = 0x04
    case invalidObject         = 0x05
    case signatureMismatch     = 0x06
    case unsupportedType       = 0x07
    case operationNotPermitted = 0x08
    case operationFailed       = 0x0A
    case extendedError         = 0x0B
    
    // Note: When more result codes are added, the corresponding DFUError
    //       case needs to be added. See `error` property below.
    
    var code: UInt8 {
        return rawValue
    }
    
    var error: DFUError {
        return DFURemoteError.secure.with(code: code)
    }
    
    var description: String {
        switch self {
            case .invalidCode:           return "Invalid code"
            case .success:               return "Success"
            case .opCodeNotSupported:    return "Operation not supported"
            case .invalidParameter:      return "Invalid parameter"
            case .insufficientResources: return "Insufficient resources"
            case .invalidObject:         return "Invalid object"
            case .signatureMismatch:     return "Signature mismatch"
            case .operationNotPermitted: return "Operation not permitted"
            case .unsupportedType:       return "Unsupported type"
            case .operationFailed:       return "Operation failed"
            case .extendedError:         return "Extended error"
        }
    }
}

internal typealias SecureDFUResponseCallback = (_ response : SecureDFUResponse) -> Void

internal struct SecureDFUResponse {
    let opCode        : SecureDFUOpCode
    let requestOpCode : SecureDFUOpCode
    let status        : SecureDFUResultCode
    let maxSize       : UInt32?
    let offset        : UInt32?
    let crc           : UInt32?
    let error         : SecureDFUExtendedErrorCode?
    
    init?(_ data: Data) {
        // The response has at least 3 bytes.
        guard data.count >= 3,
              let opCode = SecureDFUOpCode(rawValue: data[0]),
              let requestOpCode = SecureDFUOpCode(rawValue: data[1]),
              let status = SecureDFUResultCode(rawValue: data[2]),
              opCode == .responseCode else {
            return nil
        }
        
        switch status {
        case .success:
            // Parse response data in case of a success.
            switch requestOpCode {
            case .selectObject:
                // The correct reponse for Select Object has additional 12 bytes:
                // Max Object Size, Offset and CRC.
                guard data.count >= 15 else { return nil }
                let maxSize : UInt32 = data.asValue(offset: 3)
                let offset  : UInt32 = data.asValue(offset: 7)
                let crc     : UInt32 = data.asValue(offset: 11)
                
                self.maxSize = maxSize
                self.offset  = offset
                self.crc     = crc
                self.error   = nil
            case .calculateChecksum:
                // The correct reponse for Calculate Checksum has additional 8 bytes:
                // Offset and CRC.
                guard data.count >= 11 else { return nil }
                let offset : UInt32 = data.asValue(offset: 3)
                let crc    : UInt32 = data.asValue(offset: 7)
                
                self.maxSize = nil
                self.offset  = offset
                self.crc     = crc
                self.error   = nil
            default:
                self.maxSize = nil
                self.offset  = nil
                self.crc     = nil
                self.error   = nil
            }
        case .extendedError:
            // If extended error was received, the 4th byte is the extended error code.
            guard data.count >= 4,
                  let error = SecureDFUExtendedErrorCode(rawValue: data[3]) else {
                return nil
            }
            
            self.maxSize = nil
            self.offset  = nil
            self.crc     = nil
            self.error   = error
        default:
            self.maxSize = nil
            self.offset  = nil
            self.crc     = nil
            self.error   = nil
        }
        
        self.opCode        = opCode
        self.requestOpCode = requestOpCode
        self.status        = status
    }

    var description: String {
        switch status {
        case .extendedError:
            if let error = error {
                return "Response (Op Code = \(requestOpCode.rawValue), Status = \(status.rawValue), Extended Error \(error.rawValue) = \(error.description))"
            }
            return "Response (Op Code = \(requestOpCode.rawValue), Status = \(status.rawValue), Unsupported Extended Error value)"
        case .success:
            switch requestOpCode {
            case .selectObject:
                // Max size for a command object is usually around 256. Let's say 1024,
                // just to be sure. This is only for logging, so may be wrong.
                let maxSize = maxSize ?? 0
                return String(format: "\(maxSize > 1024 ? "Data" : "Command") object selected (Max size = \(maxSize), Offset = \(offset!), CRC = %08X)", crc!)
            case .calculateChecksum:
                return String(format: "Checksum (Offset = \(offset!), CRC = %08X)", crc!)
            default:
                // Other responses are either not logged, or logged by the service or executor,
                // so this 'default' should never be called.
                break
            }
            fallthrough
        default:
            return "Response (Op Code = \(requestOpCode.rawValue), Status = \(status.rawValue))"
        }
    }
}

internal struct SecureDFUPacketReceiptNotification {
    let opCode        : SecureDFUOpCode
    let requestOpCode : SecureDFUOpCode
    let resultCode    : SecureDFUResultCode
    let offset        : UInt32
    let crc           : UInt32

    init?(_ data: Data) {
        guard data.count >= 11,
              let opCode = SecureDFUOpCode(rawValue: data[0]),
              let requestOpCode = SecureDFUOpCode(rawValue: data[1]),
              let resultCode = SecureDFUResultCode(rawValue: data[2]),
              opCode == .responseCode,
              requestOpCode == .calculateChecksum,
              resultCode == .success else {
            return nil
        }
        
        self.opCode        = opCode
        self.requestOpCode = requestOpCode
        self.resultCode    = resultCode
        
        let offset : UInt32 = data.asValue(offset: 3)
        let crc    : UInt32 = data.asValue(offset: 7)

        self.offset = offset
        self.crc = crc
    }
}

internal class SecureDFUControlPoint : NSObject, CBPeripheralDelegate, DFUCharacteristic {
    
    internal var characteristic: CBCharacteristic
    internal var logger: LoggerHelper

    private var success:  Callback?
    private var response: SecureDFUResponseCallback?
    private var proceed:  ProgressCallback?
    private var report:   ErrorCallback?

    internal var valid: Bool {
        return characteristic.properties.isSuperset(of: [.write, .notify])
    }
    
    // MARK: - Initialization
    required init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }

    func peripheralDidReceiveObject() {
        proceed = nil
    }

    // MARK: - Characteristic API methods
    
    /**
     Enables notifications for the DFU Control Point characteristics.
     Reports success or an error using callbacks.
    
     - parameter success: Method called when notifications were successfully enabled.
     - parameter report:  Method called in case of an error.
     */
    func enableNotifications(onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Get the peripheral object.
        let optService: CBService? = characteristic.service
        guard let peripheral = optService?.peripheral else {
            report?(.invalidInternalState, "Assert characteristic.service?.peripheral != nil failed")
            return
        }
        
        // Save callbacks.
        self.success  = success
        self.response = nil
        self.report   = report
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        let controlPointUUID = characteristic.uuid.uuidString
        
        logger.v("Enabling notifications for \(controlPointUUID)...")
        logger.d("peripheral.setNotifyValue(true, for: \(controlPointUUID))")
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    /**
     Sends given request to the DFU Control Point characteristic.
     Reports success or an error using callbacks.
     
     - parameter request: Request to be sent.
     - parameter success: Method called when peripheral reported with status success.
     - parameter report:  Method called in case of an error.
     */
    func send(_ request: SecureDFURequest,
              onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Get the peripheral object.
        let optService: CBService? = characteristic.service
        guard let peripheral = optService?.peripheral else {
            report?(.invalidInternalState, "Assert characteristic.service?.peripheral != nil failed")
            return
        }
        
        // Save callbacks and parameter.
        self.success  = success
        self.response = nil
        self.report   = report
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        let controlPointUUID = characteristic.uuid.uuidString
        
        logger.v("Writing to characteristic \(controlPointUUID)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(controlPointUUID), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    /**
     Sends given request to the DFU Control Point characteristic.
     Reports received data or an error using callbacks.
     
     - parameter request:  Request to be sent.
     - parameter response: Method called when peripheral sent a notification with requested
                           data and status success.
     - parameter report:   Method called in case of an error.
     */
    func send(_ request: SecureDFURequest,
              onResponse response: SecureDFUResponseCallback?, onError report: ErrorCallback?) {
        // Get the peripheral object.
        let optService: CBService? = characteristic.service
        guard let peripheral = optService?.peripheral else {
            report?(.invalidInternalState, "Assert characteristic.service?.peripheral != nil failed")
            return
        }
        
        // Save callbacks and parameter.
        self.success  = nil
        self.response = response
        self.report   = report
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        let controlPointUUID = characteristic.uuid.uuidString
        
        logger.v("Writing to characteristic \(controlPointUUID)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(controlPointUUID), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    /**
     Sets the callbacks used later on when a Packet Receipt Notification is received,
     a device reported an error or the whole firmware has been sent. 
     Sending the firmware is done using DFU Packet characteristic.
     
     - parameter success: Method called when peripheral reported with status success.
     - parameter proceed: Method called the a PRN has been received and sending following data
                          can be resumed.
     - parameter report:  Method called in case of an error.
     */
    func waitUntilUploadComplete(onSuccess success: Callback?,
                                 onPacketReceiptNofitication proceed: ProgressCallback?,
                                 onError report: ErrorCallback?) {
        // Get the peripheral object.
        let optService: CBService? = characteristic.service
        guard let peripheral = optService?.peripheral else {
            report?(.invalidInternalState, "Assert characteristic.service?.peripheral != nil failed")
            return
        }
        
        // Save callbacks. The proceed callback will be called periodically whenever a packet
        // receipt notification is received. It resumes uploading.
        self.success = success
        self.proceed = proceed
        self.report  = report
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        logger.a("Uploading firmware...")
        logger.v("Sending firmware to DFU Packet characteristic...")
    }

    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.e("Enabling notifications failed. Check if Service Changed service is enabled.")
            logger.e(error)
            // Note:
            // Error 253: Unknown ATT error.
            // This most proably is caching issue. Check if your device had Service Changed
            // characteristic (for non-bonded devices) in both app and bootloader modes.
            // For bonded devices make sure it sends the Service Changed indication after
            // connecting.
            report?(.enablingControlPointFailed, "Enabling notifications failed")
            return
        }
        logger.v("Notifications enabled for \(characteristic.uuid.uuidString)")
        logger.a("Secure DFU Control Point notifications enabled")
        success?()
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // This method, according to the iOS documentation, should be called only after writing
        // with response to a characteristic. However, on iOS 10 this method is called even after
        // writing without response, which is a bug. The DFU Control Point characteristic always
        // writes with response, in oppose to the DFU Packet, which uses write without response.
        guard self.characteristic.isEqual(characteristic) else {
            return
        }

        if let error = error {
            logger.e("Writing to characteristic failed. Check if Service Changed service is enabled.")
            logger.e(error)
            // Note:
            // Error 3: Writing is not permitted.
            // This most proably is caching issue. Check if your device had Service Changed
            // characteristic (for non-bonded devices) in both app and bootloader modes. This
            // is a specially a case in SDK 12.x, where it was disabled by default.
            // For bonded devices make sure it sends the Service Changed indication after connecting.
            report?(.writingCharacteristicFailed, "Writing to characteristic failed")
            return
        }
        logger.i("Data written to \(characteristic.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // Ignore updates received for other characteristics
        guard self.characteristic.isEqual(characteristic) else {
            return
        }

        if let error = error {
            // This characteristic is never read, the error may only pop up when notification
            // is received.
            logger.e("Receiving notification failed")
            logger.e(error)
            report?(.receivingNotificationFailed, "Receiving notification failed")
            return
        }
        
        guard let characteristicValue = characteristic.value else { return }
        
        // During the upload we may get either a Packet Receipt Notification, or a Response
        // with status code.
        if let proceed = proceed,
           let prn = SecureDFUPacketReceiptNotification(characteristicValue) {
            proceed(prn.offset) // The CRC is not verified after receiving a PRN, only the offset is.
            return
        }
        // Otherwise...
        logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x): \(characteristicValue.hexString)")

        // Parse response received.
        guard let dfuResponse = SecureDFUResponse(characteristicValue) else {
            logger.e("Unknown response received: 0x\(characteristicValue.hexString)")
            report?(.unsupportedResponse, "Unsupported response received: 0x\(characteristicValue.hexString)")
            return
        }
        
        switch dfuResponse.status {
        case .success:
            switch dfuResponse.requestOpCode {
            case .selectObject, .calculateChecksum:
                logger.a("\(dfuResponse.description) received")
                response?(dfuResponse)
            case .createObject, .setPRNValue, .execute:
                // Don't log, executor or service will do it for us.
                success?()
            default:
                logger.a("\(dfuResponse.description) received")
                success?()
            }
        case .extendedError:
            // An extended error was received.
            logger.e("Error \(dfuResponse.error!.code): \(dfuResponse.error!.description)")
            report?(dfuResponse.error!.error, dfuResponse.error!.description)
        default:
            logger.e("Error \(dfuResponse.status.code): \(dfuResponse.status.description)")
            report?(dfuResponse.status.error, dfuResponse.status.description)
        }
    }
    
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        // On iOS 11 and MacOS 10.13 or newer PRS are no longer required. Instead,
        // the service checks if it can write write without response before writing
        // and it will get this callback if the buffer is ready again.
        proceed?(nil) // no offset available
    }
}
