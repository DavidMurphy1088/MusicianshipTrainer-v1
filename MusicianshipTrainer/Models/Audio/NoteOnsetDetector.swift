//import AVFoundation
//
//func calculateOnsetPoints(audioURL: URL, sampleRate: Double, frameSize: Int, hopSize: Int, energyThreshold: Double, onsetThreshold: Double) -> [Double] {
//    guard let audioFile = try? AVAudioFile(forReading: audioURL) else {
//        print("Error: Unable to open audio file")
//        return []
//    }
//
//    let audioFormat = audioFile.processingFormat
//    let audioFrameCount = UInt32(audioFile.length)
//    let audioPCMBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
//
//    do {
//        try audioFile.read(into: audioPCMBuffer!)
//    } catch {
//        print("Error: Failed to read audio file")
//        return []
//    }
//
//    guard let audioData = audioPCMBuffer?.floatChannelData else {
//        print("Error: Failed to get audio data")
//        return []
//    }
//
//    let numChannels = Int(audioFormat.channelCount)
//    let numFrames = Int(audioPCMBuffer!.frameLength)
//
//    // Calculate the ODF
//    var odf = [Double]()
//    var prevEnergy = 0.0
//
//    for channel in 0..<numChannels {
//        for frame in 0..<numFrames {
//            let sample = audioData[channel][frame]
//
//            // Calculate energy
//            let energy = Double(sample * sample)
//            
//            // Calculate ODF
//            let diffEnergy = energy - prevEnergy
//
//            odf.append(diffEnergy > energyThreshold ? diffEnergy : 0)
//            
//            if frame % 5000 == 0 {
//                print (frame, "energy:", energy, "diff:", diffEnergy, "ODF count:", odf.count)
//            }
//
//            prevEnergy = energy
//        }
//    }
//
//    // Calculate note onset points
//    var onsetPoints = [Double]()
//    var prevValue = 0.0
//    let threshold = onsetThreshold * odf.max()!
//    print("thresh:", threshold, "max", odf.max())
//    
//    for i in 0..<odf.count {
//        let value = odf[i]
//
//        if value > threshold && value > prevValue {
//            let time = Double(i * hopSize) / sampleRate
//            onsetPoints.append(time)
//        }
//
//        prevValue = value
//    }
//
//    return onsetPoints
//}
