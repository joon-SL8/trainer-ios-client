//
//  IOSFitFileProcessor.swift
//  mobile
//
//  Created by Joon Lee on 12/16/25.
//

import Foundation
import ObjcFIT
import SwiftFIT
import libfitness

public class IOSFitFileProcessor : NSObject, FitProcessor {
    let documentsPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""

    public func processFitFileData(
        filename: String,
        content: FitContent
    ) -> FileCreateResult {
        let filePath = documentsPathString + "/" + filename

        let fileEncoder = FITEncoder(version: .V20)
        fileEncoder.open(filePath)

        let now = FITDate()

        let fileHeader = FITFileIdMesg()
        fileHeader.setType(FITFileWorkout)
        fileHeader.setProduct(1)
        fileHeader.setProductName("Trainer.mobile.ios")
        fileHeader.setManufacturer(FITManufacturerDevelopment)
        fileHeader.setTimeCreated(now)
        fileEncoder.write(fileHeader)
        
        content.forEachRecordPerform {
            let key = $0
            let data = $1

            let recordMesg = FITRecordMesg()
            let timestamp = FITDate(timestamp: UInt32(truncating: key))

            recordMesg.setTimestamp(timestamp)
            recordMesg.setPower(UInt16(data.power))
            recordMesg.setHeartRate(UInt8(data.heartRate))
            recordMesg.setCadence(UInt8(data.cadence))
            recordMesg.setSpeed(Float(data.speed))
            print("timestamp: \(timestamp)")

            fileEncoder.write(recordMesg)
        }

        print("File (\(filename)): session message")
        let sessionMesg = FITSessionMesg()
        sessionMesg.setTimestamp(now)
        sessionMesg.setEventType(FITEventTypeStop)
        sessionMesg.setSport(FITSportCycling)
        sessionMesg.setSubSport(FITSubSportIndoorCycling)
        fileEncoder.write(sessionMesg)

        print("File (\(filename)): session message")
        let activityMesg = FITActivityMesg()
        activityMesg.setTimestamp(now)
        activityMesg.setEventType(FITEventTypeStop)
        activityMesg.setNumSessions(1)
        activityMesg.setType(FITActivityManual)
        fileEncoder.write(activityMesg)
        
        fileEncoder.close()

        print("File Generated \(filePath) - \(filename)")
        copyToDownloads(filename: filename)
        return .Success(fileUrl: filename)
    }

    private func copyToDownloads(filename: String) {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let downloadsDir = documentsDir.appendingPathComponent("Downloads", isDirectory: true)
        
        // Create the directory if it doesn't exist
        try? fileManager.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
        
        let sourceURL = documentsDir.appendingPathComponent(filename)
        let destinationURL = downloadsDir.appendingPathComponent(filename)
        
        // Remove if exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("File copied to \(destinationURL.path)")
        } catch {
            print("Error copying file to Downloads: \(error)")
        }
    }

    public func loadFitFile(filename: String) -> KotlinByteArray {
        let filePath = documentsPathString + "/" + filename

        let decode = FITDecoder()
        let result = decode.decodeFile(filePath)
        print("decoded file: \(result.description)")

        return NSDataUtilKt.loadFileToByteArray(filename: filePath)
    }
}
