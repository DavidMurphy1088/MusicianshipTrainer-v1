import AVFoundation

class Test {
    
    func measurePitch(fileName: String) -> Float? {

        do {
            let url = Bundle.main.url(forResource: fileName, withExtension: "wav")
            var audioFile = try AVAudioFile(forReading: url!)
            let format = audioFile.processingFormat
            //let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioFile.length))
            
            let audioEngine = AVAudioEngine()
            let audioInputNode = audioEngine.inputNode
            
            // Connect the input node to the main mixer node
            let mainMixerNode = audioEngine.mainMixerNode
            audioEngine.connect(audioInputNode, to: mainMixerNode, format: format)
            
            // Start the audio engine
            try audioEngine.start()
            
            // Create an audio converter to convert the input format to the desired processing format
            let inputFormat = audioInputNode.inputFormat(forBus: 0)
            let converter = AVAudioConverter(from: inputFormat, to: format)!
            
            // Prepare the audio engine for manual rendering
            audioEngine.prepare()
            
            // Determine the frame capacity of the audio buffer
            let frameCapacity = AVAudioFrameCount(4096) // Adjust this value as needed
            
            // Create a buffer for manual rendering
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)
            
            // Create an audio file buffer for reading the audio file
            let fileBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCapacity)
            try audioFile.read(into: fileBuffer!)
            
            // Perform manual rendering and process the audio samples
            try audioEngine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: frameCapacity)
            var frameOffset = 0
            
            while audioEngine.manualRenderingSampleTime < fileBuffer!.frameLength {
                let framesToRender = min(frameCapacity, fileBuffer!.frameLength - UInt32(audioEngine.manualRenderingSampleTime))
                
                let status = try audioEngine.renderOffline(framesToRender, to: buffer!)
                
                switch status {
                case .success:
                    // Process the audio samples in the buffer
                    let floatBuffer = Array(UnsafeBufferPointer(start: buffer!.floatChannelData?[0], count: Int(framesToRender)))
                    let pitch = performPitchDetection(floatBuffer, sampleRate: Float(format.sampleRate))
                    print("Detected pitch: \(pitch)")
                    
                    // Update the frame offset
                    frameOffset += Int(framesToRender)
                    
                case .insufficientDataFromInputNode:
                    // Handle insufficient data if necessary
                    break
                    
                case .cannotDoInCurrentContext:
                    // Handle context error if necessary
                    break
                    
                case .error:
                    // Handle other errors if necessary
                    break
                }
            }
            
            // Stop the audio engine
            audioEngine.stop()
            
            return nil
        } catch {
            print("Error processing audio: \(error)")
            return nil
        }
    }

//============================================================
    
    func measurePitch1(fileName:String) -> Float? {
        do {
            let url = Bundle.main.url(forResource: fileName, withExtension: "wav") 
            var audioFile = try AVAudioFile(forReading: url!)
            let format = audioFile.processingFormat
            //let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioFile.length))
            
            // Create an instance of AVAudioEngine
            let audioEngine = AVAudioEngine()
            let audioInputNode = audioEngine.inputNode
            
            // Connect the input node to the main mixer node
            let mainMixerNode = audioEngine.mainMixerNode
            audioEngine.connect(audioInputNode, to: mainMixerNode, format: format)
            
            // Install a tap on the audio input node to get the audio samples
            audioInputNode.installTap(onBus: 0, bufferSize: 4096, format: audioInputNode.inputFormat(forBus: 0)) { (buffer, time) in
                // Process the audio samples
                let floatBuffer = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: Int(buffer.frameLength)))
                
                // Perform pitch detection on the floatBuffer to get the pitch value
                let pitch = self.performPitchDetection(floatBuffer, sampleRate: Float(format.sampleRate))
                
                // Use the pitch value as needed
                print("Detected pitch: \(pitch)")
            }
            
            // Start the audio engine
            try audioEngine.start()
            
            // Schedule the audio file for playback
            let audioPlayerNode = AVAudioPlayerNode()
            audioEngine.attach(audioPlayerNode)
            audioEngine.connect(audioPlayerNode, to: mainMixerNode, format: format)
            
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioFile.length))
            try audioFile.read(into: buffer!)
            audioPlayerNode.scheduleBuffer(buffer!, completionHandler: nil)
            audioPlayerNode.play()
            
            usleep(1000000 * UInt32(6.0))
            // Stop the audio engine
            audioEngine.stop()
        } catch {
            print("Error processing audio: \(error)")
            return nil
        }
        return nil
    }
    
    func performPitchDetection(_ audioSamples: [Float], sampleRate: Float) -> Float? {
        let bufferSize = audioSamples.count
        let threshold: Float = 0.15 // Adjust the threshold as needed
        
        // Step 1: Calculate the difference function
        var differenceFunction = [Float](repeating: 0.0, count: bufferSize)
        for tau in 0..<bufferSize {
            for j in 0..<bufferSize - tau {
                //differenceFunction[tau] += (audioSamples[j] - audioSamples[j + tau]).squared()
                let t = (audioSamples[j] - audioSamples[j + tau])
                differenceFunction[tau] += t * t
            }
        }
        
        // Step 2: Calculate the cumulative mean normalized difference function (CMND)
        var cumulativeMeanNormalizedDifference = [Float](repeating: 0.0, count: bufferSize)
        cumulativeMeanNormalizedDifference[0] = 1.0
        for tau in 1..<bufferSize {
            var cumulativeSum = Float(0)
            for j in 1...tau {
                cumulativeSum += differenceFunction[j]
            }
            cumulativeMeanNormalizedDifference[tau] = differenceFunction[tau] / ((1.0 / Float(tau) * cumulativeSum))
        }
        
        // Step 3: Find the minimum value of the CMND (excluding the first value)
        var minIndex = 0
        var minValue = Float.infinity
        for tau in 1..<bufferSize {
            if cumulativeMeanNormalizedDifference[tau] < minValue {
                minValue = cumulativeMeanNormalizedDifference[tau]
                minIndex = tau
            }
        }
        
        // Step 4: Interpolate the minimum value to improve accuracy
        if minIndex > 0 && minIndex < bufferSize - 1 {
            let y1 = cumulativeMeanNormalizedDifference[minIndex - 1]
            let y2 = cumulativeMeanNormalizedDifference[minIndex]
            let y3 = cumulativeMeanNormalizedDifference[minIndex + 1]
            let a = (y1 + y3 - (2.0 * y2)) / 2.0
            let b = (y3 - y1) / 2.0
            if a != 0 {
                let interpolatedIndex = Float(minIndex) - (b / (2.0 * a))
                return sampleRate / interpolatedIndex
            } else {
                return sampleRate / Float(minIndex)
            }
        } else {
            return sampleRate / Float(minIndex)
        }
    }

//    extension FloatingPoint {
//        func squared() -> Self {
//            return self * self
//        }
//
//        func toFloat() -> Float {
//            return Float(self)
//        }
//    }
}
