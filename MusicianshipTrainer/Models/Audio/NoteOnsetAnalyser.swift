import Foundation
import SwiftUI
import CoreData
import AVFoundation
import Accelerate

class NoteOnsetAnalyser : ObservableObject {
    var frameValues:[Float] = []
    
    var frameValuesBySegment:[[Float]] = []

    var segmentAverages:[Float] = []
    @Published var segmentAveragesPublished:[Float] = []
    
    var pitchInputValuesWindowed:[Float] = []
    @Published var pitchInputValuesWindowedPublished:[Float] = []
    
    var pitchInputValues:[Float] = []
    @Published var pitchInputValuesPublished:[Float] = []

    var pitchOutputValues:[Float] = []
    @Published var pitchOutputValuesPublished:[Float] = []

    @Published var sampleTime:Double = 0.0
    @Published var status:String = ""
    
    var framesPerSegment:Int = 0
    var audioFile:AVAudioFile?
    var samplingRate:Double = 0
    var correctNotes:[(Double, Double)] = []
    
    func setTimeSlice() {
        DispatchQueue.main.async {
            self.sampleTime = 1000.0 / self.sampleTime
        }
    }
    
    func reset() {
        self.frameValues = []
        self.frameValuesBySegment = []
        self.segmentAverages = []
        self.pitchInputValuesWindowed = []
        self.pitchInputValues = []
        self.pitchOutputValues = []
    }
    
    func setStatus(_ msg:String) {
        //print("NoteOnsetAnalyser \(msg)")
        DispatchQueue.main.async {
            self.status = self.status
        }
    }
            
    //Segment a sound recordings into segments of specified length time
    func segmentWavFile(url:URL, segmentLengthSecondsMilliSec: TimeInterval) -> [[Float]]? {
        do {
            var audioFile = try AVAudioFile(forReading: url)
            self.samplingRate = audioFile.fileFormat.sampleRate
            
            framesPerSegment = Int(AVAudioFrameCount(segmentLengthSecondsMilliSec * audioFile.fileFormat.sampleRate / 1000.0))
            let duration = Double(audioFile.length) / audioFile.fileFormat.sampleRate
            
            let totalSegmentCount = Int(audioFile.length / Int64(framesPerSegment))
            self.setStatus("segmentWavFile::start")
            
            //=========== read the whole file to get average and maximum
            
            let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
            var maxValue:Double = 0.0
            self.frameValues = []
            
            if let audioBuffer = audioBuffer {
                try audioFile.read(into: audioBuffer)

                if let floatChannelData = audioBuffer.floatChannelData {
                    let channelCount = Int(audioFile.processingFormat.channelCount)
                    let frameLength = Int(audioBuffer.frameLength)
                    var ctr = 0
                    var totalValue:Double = 0.0
                    
                    // Iterate over the audio frames and access the sample values
                    for frame in 0..<frameLength {
                        var channelTotal = 0.0
                        for channel in 0..<channelCount {
                            let sampleValue = Double(floatChannelData[channel][frame])
                            channelTotal += sampleValue
                            if Double(sampleValue) > maxValue {
                                maxValue = Double(sampleValue)
                            }
                            totalValue += sampleValue
                            ctr += 1
                        }
                        self.frameValues.append(Float(channelTotal))
                    }
                    //print ("totalFrames:", frameLength, "maxValue:", maxValue, "AvgValue:", totalValue / Double(frameLength))
                    print ("segmentWavFile::",
                           "\n  URL", url,
                           "\n  audioDuration:", duration,
                           "\n  sample rate per sec:", audioFile.fileFormat.sampleRate,
                           "\n  totalFramesCount:", audioBuffer.frameLength,
                           "\n  segmentLengthSeconds ms:", segmentLengthSecondsMilliSec,
                           "\n  number of segments:", totalSegmentCount,
                           "\n  samplesPerSegment:", framesPerSegment
//                           "\n  maxValue:", maxValue,
//                           "\n  AvgValue:", totalValue / Double(frameLength)
                           )
                }
            }
        
             // ============== make the segments
            audioFile = try AVAudioFile(forReading: url) //required again since the scan of the whole file above makes this next code fail
            let threshold = maxValue * 0.2 //TODO UI??
            var frameCtr = 0

            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioFile.fileFormat.sampleRate,
                                       channels: audioFile.fileFormat.channelCount, interleaved: false)
            for segmentIndex in 0..<totalSegmentCount {
                let startSample = AVAudioFramePosition(segmentIndex) * AVAudioFramePosition(framesPerSegment)
                let framesBuffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(framesPerSegment))!
                
                try audioFile.read(into: framesBuffer)
                let floatChannelData = framesBuffer.floatChannelData!
                let channelCount = Int(framesBuffer.format.channelCount)
                
                var frameData: [Float] = []
                for frame in 0..<Int(framesPerSegment) {
                    let sample = floatChannelData.pointee[frame * channelCount]
                    if abs(sample) > Float(threshold) { //TODO
                        frameData.append(sample)
                    }
                    else {
                        frameData.append(0.0)
                    }
                    //self.frameValues.append(sample)
                }

                var segmentData:[Float]
                if false { //TODO
                    segmentData = applyHighPassFilter(signal: frameData, cutoffFrequency: 220.0, sampleRate: Float(audioFile.fileFormat.sampleRate))
                }
                else {
                    segmentData = Array(frameData)
                }
                self.frameValuesBySegment.append(segmentData)
            }
            self.setStatus("segmentWavFile::end")
            return self.frameValuesBySegment
        } catch {
            print("Error loading file: \(error.localizedDescription)")
            return nil
        }
    }

    //Collapse the segment frame values to an average per segment
    func makeSegmentAverages(fileName:String, segmentLengthSecondsMilliSec: Double) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
            print("File  not found in the app bundle.")
            return
        }
        
        //typically 10-50 milliseconds.
        self.segmentAverages = []

        if let segments = segmentWavFile(url: url, segmentLengthSecondsMilliSec: segmentLengthSecondsMilliSec) {
            for segmentIndex in 0..<segments.count {
                let segmentData = segments[segmentIndex]
                let sum = segmentData.reduce(0, +)
                let average = (Float(sum) / Float(segmentData.count)) * 1000
                self.segmentAverages.append(average)
             }
        }
        DispatchQueue.main.async {
            self.segmentAveragesPublished = []
            for i in 0..<self.segmentAverages.count {
                self.segmentAveragesPublished.append(self.segmentAverages[i] / 1.0)
                self.sampleTime = segmentLengthSecondsMilliSec //1.0 / sampleTimeDivisor
            }
        }
    }

    //Use the segmented audio frames to detect note onset.
    //Then for each note duration feed the correspondg auio frames in FFT for pitch analsysis
    func detectNoteOnsets(noteOnsetSliceMilliSecs:Double, segmentLengthSecondsMilliSec: Double,
                          FFTFrameSize:Int, FFTFrameOffset:Int) {
        self.correctNotes = [(64,2), (62,2), (60,1), (62,1), (64,2), (67,4), (67,4), (65,2), (67,2)]
        //var segmentsPerSlice = Int(Double(self.segmentAverages.count) * noteOnsetSliceWidthPercent)
        var segmentsPerSlice = Int(noteOnsetSliceMilliSecs / segmentLengthSecondsMilliSec)
        
        //var segmentsPerSlice = 1 //TODO
        if segmentsPerSlice == 0 {
            print("==========Zero segments pe slice")
            return
        }
        print("\ndetectNotes::",
              "\n  SegmentsCount:", self.segmentAverages.count,
              "\n  NoteOnsetSliceMilliSecs", noteOnsetSliceMilliSecs,
              "\n  SegmentsPerSlice:", segmentsPerSlice,
              "\n  SegmentLengthSecondsMilliSec:", segmentLengthSecondsMilliSec)
              //"\n  MaxSegAvg:", self.segmentAverages.max() ?? 0)
        
        let maxAmplitude = self.segmentAverages.max() ?? 0
        let amplitudeChangeThreshold = maxAmplitude * 0.015
        var notesCount = 0
        
        var lastNoteIdx:Int?
        var noteOffsets:[NoteOffset] = []
        
        //find the note onsets by looking for amplitude bumps in slices of the segment averages
        var segmentIdx = segmentsPerSlice
        while segmentIdx < self.segmentAverages.count {
            let prev = subArray(array: self.segmentAverages, at: segmentIdx, fwd:false, len: segmentsPerSlice)
            let next = subArray(array: self.segmentAverages, at: segmentIdx, fwd:true, len: segmentsPerSlice)
            let prevAvg = prev.reduce(0, +)
            let nextAvg = next.reduce(0, +)
            if nextAvg - prevAvg > amplitudeChangeThreshold {
                //save the note location and value
                if let lastNoteIdx = lastNoteIdx {
                    let lastNoteOffset = NoteOffset(startSegment: lastNoteIdx, endSegment: segmentIdx)
                    noteOffsets.append(lastNoteOffset)
                }
                
                notesCount += 1
                lastNoteIdx = segmentIdx
                
                //jump ahead to next note, assume shortest note is value 1/4 of 1.0
                let segmentsPerSec = 1000.0 / segmentLengthSecondsMilliSec
                let jumpAhead = max(Int(segmentsPerSec / 4.0), 1)
                segmentIdx += jumpAhead
            }
            else {
                segmentIdx += segmentsPerSlice
            }
        }
        
        //======================== Calculate the pitch of the signal frames during the note durations =======================================
        if noteOffsets.count < 2 {
            print("=========NO NOTE OFFSETS")
            return
        }
        let firstNoteDuration = noteOffsets[1].duration() / 2.0 //should be offset 0 and not div by 2. Tempoarily adjusted now for sequencer
        var pitches:[Double] = []
        
        //Gather the frames to give FFT based on the note offsets detected
        for i in 0..<noteOffsets.count {
            let offset = noteOffsets[i]
            var inputFrameValues:[Float] = []
            var startFrame = offset.startSegment * self.framesPerSegment
            startFrame += FFTFrameOffset
            let endFrame = startFrame + Int(offset.duration()) * self.framesPerSegment
            let frameCnt = endFrame - startFrame
            //let requiredValues = Int(Double(frameCnt * FFTFrameSizePercent) / 100.0)
            let requiredValues = FFTFrameSize
            var ctr = 0
            for j in startFrame...endFrame {
                //inputFrameValues.append(self.frameValues[j])
                inputFrameValues.append(self.frameValues[j])
                if ctr > requiredValues {
                    break
                }
                ctr += 1
            }
            
            var pitch:Int? = 0

            //Window functions like Hamming are applied to segments of a signal before further analysis to mitigate the adverse effects of spectral leakage.
                
                //let pitch = performYINalgorithm(floats, sampleRate: Float(self.samplingRate))
                //let yin = performYINPitchDetection(hammed, sampleRate: Float(self.samplingRate)) //slow and always returns 0
                //pitch = Double(yin ?? 0)
            
            //let fourierTransformValues = FFTTap.performFFT(buffer: frameValues) // from AudiKit Cookbook
            let windowedValues = applyHammingWindow(to: inputFrameValues)
            //let FFTValues = self.performFourierTransform(input: arrayToDouble(frameValues))
            
            let FFTOutputValues = self.performFourierTransform(input: arrayToDouble(windowedValues))
            //pitch = extractPitchFromFFTResult(arrayToFloat(FFTValues), sampleRate: Float(self.samplingRate))
            //pitch = findDominantPitch(fftOutput: arrayToFloat(FFTOutputValues), sampleRate: Float(self.samplingRate))
            
            let f:Float? = performPeakInterpolation(fftOutput: arrayToFloat(FFTOutputValues), sampleRate: Float(self.samplingRate))
            pitch = f == nil ? 0 : Int(f!)
            
//            print("Note", i,
//                  "Value:", String(format: "%.2f", offset.duration() / firstNoteDuration),
//                  "\n  SegmentsDuration:", offset.duration(),
////                  "\n  StartSegment:", offset.startSegment,
////                  "\n  EndSegment:", offset.startSegment + Int(offset.duration()),
//                  "\n  Frames:", endFrame - startFrame,
//                  //"\n  FourierInCount:", frameValues.count
//                  "\n  Pitch:", pitch ?? 0
//            )
            
            //publish data
            pitches.append(Double(pitch!) )
            if i == 1 {
                //DispatchQueue.main.async {
                    self.pitchInputValuesPublished = []
                    self.pitchInputValuesWindowedPublished = []
                    self.pitchOutputValues = []
                    for f in inputFrameValues {
                        self.pitchInputValuesPublished.append(f)
                    }
                    for f in windowedValues {
                        self.pitchInputValuesWindowedPublished.append(f)
                    }
                    for f in FFTOutputValues {
                        self.pitchOutputValuesPublished.append(Float(f))
                    }
                //}
            }
        }
        
        var result:[(Double, Double)] = []
        for i in 0..<noteOffsets.count {
            let value = noteOffsets[i].duration() / firstNoteDuration
//            print("\(i)  pitch:" + String(format: "%.0f", pitches[i]) + " value:" + String(format: "%.2f", value))
            result.append((pitches[i], value))
        }
        self.analyseForCorrectness(results: result)

    }
    func close(_ n1:Double, _ n2:Double) -> Bool {
        let diff = abs(n2-n1)
        let p = diff / n2 * 100.0
        return p < 20.0
    }
    
    func analyseForCorrectness(results:[(Double, Double)]) {
        var correctCtr = 0
        var score = 0.0
        print("===analyse===")
        for i in 0..<results.count {
            let result = results[i]
            //var out = "\(i)\tPitch:\(result.0)\tVal:\(String(format: "%.2f", result.1)))"
            var out = "\(i)\tVal:\(String(format: "%.3f", result.1)))"

            var isCorrect:Bool
            var correct:(Double, Double)?
            if i >= self.correctNotes.count {
                isCorrect = false
            }
            else {
                correct = self.correctNotes[correctCtr]
                isCorrect = close(result.1, correct!.1)
                //out += "\tCorrectNote[\(correct!.0)\tVal:\(String(format: "%.2f", correct!.1))]"
                out += "\tCorrect Val:\(String(format: "%.3f", correct!.1))"
            }
            if isCorrect {
                score += 1
            }
            out += "\tCorrect:\(isCorrect)"
            //print(out)
            correctCtr += 1
        }
        print("==>Score:", score)
    }
    
    func getSine(elements:Int, period:Double) -> [Double] {
        var res:[Double] = []
        //let p = 2.0 * Double.pi // Period of the sine wave
        let p = period * Double.pi // Period of the sine wave
        for i in 0..<elements {
            let x = Double(i) * (p / Double(elements - 1))
            let sineValue = sin(x)
            res.append(sineValue)
        }
        return res
    }
    
    
    //Window smoothing for data input to FFT
    func applyHammingWindow(to buffer: [Float]) -> [Float] {
        let length = buffer.count
        var windowedBuffer = [Float](repeating: 0.0, count: length)
        
        for i in 0..<length {
            let value = buffer[i]
            let windowMultiplier = 0.54 - 0.46 * cos(2.0 * .pi * Float(i) / Float(length - 1))
            windowedBuffer[i] = value * windowMultiplier
        }
        
        return windowedBuffer
    }
    
    //method for pitch estimation in audio signals.
    func performYINalgorithm1(_ audioSamples: [Float], sampleRate: Float) -> Float? {
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
    
    func performYINPitchDetection(_ audioSamples: [Float], sampleRate: Float) -> Float? {
        // Step 1: Calculate the ADF
        let adf = calculateAbsoluteDifferenceFunction(audioSamples)
        
        // Step 2: Calculate the CMNADF
        let cmnadf = calculateCumulativeMean(adf)
        
        // Step 3: Absolute thresholding
        let threshold: Float = 0.2 // Adjust this value as needed
        var peaks = [Int]() // Store the peak indices
        
        for tau in 1..<cmnadf.count {
            if cmnadf[tau] < threshold {
                peaks.append(tau)
            }
        }
        
        // Step 4: Select the lowest reliable peak
        let fundamentalFrequency: Float
        
        if let lowestPeak = peaks.first {
            // Interpolate the peak position for better accuracy
            let peak1 = cmnadf[lowestPeak - 1]
            let peak2 = cmnadf[lowestPeak + 1]
            
            let denominator = 2 * (peak2 - peak1)
            let interpolatedTau = Float(lowestPeak) + (peak2 - peak1) / denominator
            
            fundamentalFrequency = sampleRate / interpolatedTau
        } else {
            // No reliable peak found
            return nil
        }
        
        return fundamentalFrequency
    }

    func calculateAbsoluteDifferenceFunction(_ audioSamples: [Float]) -> [Float] {
        let frameCount = audioSamples.count
        var adf = [Float](repeating: 0.0, count: frameCount)
        
        for tau in 0..<frameCount {
            var differenceSum: Float = 0.0
            for j in 0..<(frameCount - tau) {
                differenceSum += abs(audioSamples[j] - audioSamples[j + tau])
            }
            adf[tau] = differenceSum
        }
        
        return adf
    }

    func calculateCumulativeMean(_ values: [Float]) -> [Float] {
        var cumulativeSum: Float = 0
        var cumulativeMean = [Float]()
        
        for i in 0..<values.count {
            cumulativeSum += values[i]
            cumulativeMean.append(cumulativeSum / Float(i + 1))
        }
        
        return cumulativeMean
    }
    // ===================== Filter =================

    //Allows high-frequency components to pass through while attenuating or reducing lower-frequency components.
    //It essentially removes or reduces low-frequency content from an audio signal, allowing higher-frequency content to be emphasized or preserved.
    func applyHighPassFilter(signal: [Float], cutoffFrequency: Float, sampleRate: Float) -> [Float] {
        var signal = signal

        // Calculate the number of frames in the signal
        let numFrames = vDSP_Length(signal.count)

        // Set up the high-pass filter parameters
        let nyquistFrequency = sampleRate / 2.0
        let normalizedCutoff = cutoffFrequency / nyquistFrequency
        let filterOrder = 2

        // Create the high-pass filter kernel
        var filterKernel = [Float](repeating: 0.0, count: Int(numFrames))
        let filterLength = vDSP_Length(filterKernel.count)
        let alpha = 0.5 * exp(-2.0 * .pi * normalizedCutoff)
        let beta = 2.0 * alpha * cos(2.0 * .pi * normalizedCutoff)
        filterKernel[0] = 1.0 - alpha
        filterKernel[1] = -beta

        // Apply the high-pass filter to the signal
        var filterState = [Float](repeating: 0.0, count: filterOrder)
        vDSP_deq22(signal, vDSP_Stride(1), filterKernel, &signal, vDSP_Stride(1), numFrames) //, filterLength)

        return signal
    }

    // ===================== Hamming =================

    func applyHammingWindow(signal: [Float]) -> [Float] {
        let windowSize = signal.count
        var windowedSignal = [Float](repeating: 0.0, count: windowSize)
        
        for i in 0..<windowSize {
            let windowValue = 0.54 - 0.46 * cos(2 * .pi * Float(i) / Float(windowSize - 1))
            windowedSignal[i] = signal[i] * windowValue
        }
        return windowedSignal
    }
    
    func findDominantPitch(fftOutput: [Float], sampleRate: Float) -> Int? {
        let fftSize = fftOutput.count
        let nyquistFrequency = sampleRate / 2
        let binSize = sampleRate / Float(fftSize)
        
        var maxAmplitude: Float = 0.0
        var maxBinIndex = 0
        
        for i in 0..<fftSize/2 {
            let amplitude = fftOutput[i]
            
            if amplitude > maxAmplitude {
                maxAmplitude = amplitude
                maxBinIndex = i
            }
        }
        
        let dominantFrequency = Float(maxBinIndex) * binSize
        let midiPitch = 69 + 12 * log2(dominantFrequency / 440)
        
        return Int(round(midiPitch))
    }
    
    func performPeakInterpolation(fftOutput: [Float], sampleRate: Float) -> Float? {
        let fftSize = fftOutput.count
        let nyquistFrequency = sampleRate / 2
        let binSize = sampleRate / Float(fftSize)
        
        var maxAmplitude: Float = 0.0
        var maxBinIndex = 0
        
        // Find the bin with the maximum amplitude
        for i in 0..<fftSize/2 {
            let amplitude = fftOutput[i]
            
            if amplitude > maxAmplitude {
                maxAmplitude = amplitude
                maxBinIndex = i
            }
        }
        
        // Perform peak interpolation
        let prevBinIndex = maxBinIndex - 1
        let nextBinIndex = maxBinIndex + 1
        
        guard prevBinIndex >= 0, nextBinIndex < fftSize/2 else {
            // Peak interpolation cannot be performed at the boundaries
            return nil
        }
        
        let prevAmplitude = fftOutput[prevBinIndex]
        let nextAmplitude = fftOutput[nextBinIndex]
        
        let numerator = 0.5 * (prevAmplitude - nextAmplitude)
        let denominator = prevAmplitude - 2 * maxAmplitude + nextAmplitude
        let interpolatedBinIndex = Float(maxBinIndex) + numerator / denominator
        let interpolatedFrequency = interpolatedBinIndex * binSize
        let midiPitch = 69 + 12 * log2(interpolatedFrequency / 440)
        return midiPitch
    }
    
    func subArray(array:[Float], at:Int, fwd: Bool, len:Int) -> [Float] {
        var res:[Float] = []
        let sign = 1.0 //array[at] < 0.0 ? -1.0 : 1.0
        if fwd {
            if at + len >= array.count - 1 {
                return res
            }
            let to = at+len
            for i in at..<to {
                res.append(array[i] * array[i] * Float(sign))
            }
        }
        else {
            if at - len < 0 {
                return res
            }
            let from = at-len
            for i in from..<at {
                res.append(array[i] * array[i] * Float(sign))
            }
        }
        return res
    }
    
    class NoteOffset {
        var startSegment:Int
        var endSegment:Int
        init(startSegment:Int, endSegment:Int) {
            self.startSegment = startSegment
            self.endSegment = endSegment
        }
        func duration() -> Double {
            return Double(endSegment - startSegment)
        }
    }
    
    func extractPitchFromFFTResult(_ fftResult: [Float], sampleRate: Float) -> Double? {
        let fftSize = vDSP_Length(fftResult.count)

        // Find the index with the maximum amplitude
        var maxAmplitude: Float = 0
        var maxAmplitudeIndex: vDSP_Length = 0
        vDSP_maxvi(fftResult, 1, &maxAmplitude, &maxAmplitudeIndex, fftSize)

        // Calculate the corresponding frequency bin
        let binFrequency = sampleRate / Float(fftSize)
        let dominantFrequency = Double(maxAmplitudeIndex) * Double(binFrequency)

        // Convert frequency to pitch (in MIDI note number)
        let pitch = 69 + 12 * log2(dominantFrequency / 440)

        return pitch
    }
    
    func arrayToFloat(_ doubleArray: [Double]) -> [Float] {
        return doubleArray.map { Float($0) }
    }
    
    func arrayToDouble(_ doubleArray: [Float]) -> [Double] {
        return doubleArray.map { Double($0) }
    }
    
    //Function to perform Fourier Transform on an array of numbers
    func performFourierTransform(input: [Double]) -> [Double] {
        let length = vDSP_Length(input.count)
        let log2n = vDSP_Length(log2(Double(length)))

        // Setup the input/output buffers
        var realPart = [Double](input)
        var imaginaryPart = [Double](repeating: 0.0, count: input.count)
        var splitComplex = DSPDoubleSplitComplex(realp: &realPart, imagp: &imaginaryPart)

        // Create and initialize the FFT setup
        guard let fftSetup = vDSP_create_fftsetupD(log2n, FFTRadix(kFFTRadix2)) else {
            fatalError("Failed to create FFT setup")
        }

        // Perform the Fourier Transform
        vDSP_fft_zipD(
            fftSetup,
            &splitComplex,
            1,
            log2n,
            FFTDirection(FFT_FORWARD)
        )

        // Release the FFT setup
        vDSP_destroy_fftsetupD(fftSetup)

        return realPart
    }

    
//    func applyWindow(inputBuffer: AVAudioPCMBuffer, outputBuffer: AVAudioPCMBuffer) {
//        let frameCount = Int(inputBuffer.frameLength)
//        let channelCount = Int(inputBuffer.format.channelCount)
//
//        // Apply the Hamming window to each channel of the audio data
//        for channel in 0..<channelCount {
//            guard let inputChannelData = inputBuffer.floatChannelData?[channel],
//                  let outputChannelData = outputBuffer.floatChannelData?[channel] else {
//                return
//            }
//
//            // Apply the Hamming window to the audio samples
//            for i in 0..<frameCount {
//                let windowValue = 0.54 - 0.46 * cos(2 * .pi * Float(i) / Float(frameCount - 1))
//                outputChannelData[Int(i)] = inputChannelData[Int(i)] * windowValue
//            }
//        }
//
//        // Set the frame length of the output buffer to match the input buffer
//        outputBuffer.frameLength = inputBuffer.frameLength
//    }
//
//    func makeHammedAudioFile(fileName:String, outputName: String) {
//        do {
//            let chunkSize:AVAudioFrameCount = AVAudioFrameCount(4096 * 0.10)
//            let url = Bundle.main.url(forResource: fileName, withExtension: "wav")
//            //let outUrl = Bundle.main.url(forResource: outputName, withExtension: "wav")
//
//            let inputFile = try AVAudioFile(forReading: url!)
//
//            let formatSettings: [String: Any] = [
//                AVFormatIDKey: kAudioFormatLinearPCM,
//                AVSampleRateKey: 44100.0,
//                AVNumberOfChannelsKey: 2,
//                AVLinearPCMBitDepthKey: 16,
//                AVLinearPCMIsFloatKey: false
//            ]
//
//            // Create an AVAudioFormat object based on the format settings
//            guard let outputFormat = AVAudioFormat(settings: formatSettings) else {
//                return
//            }
//            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//                return
//            }
//
//            let outUrl = documentsDirectory.appendingPathComponent("\(outputName)_\(Double(chunkSize)).m4a")
//            let outputFile = try AVAudioFile(forWriting: outUrl, settings: outputFormat.settings)
//
//            let inputFormat = inputFile.fileFormat
//            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFile.processingFormat, frameCapacity: AVAudioFrameCount(inputFile.length))
//            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFile.processingFormat, frameCapacity: AVAudioFrameCount(chunkSize))
//            let chunkTimeLen = Double(chunkSize) / inputFile.fileFormat.sampleRate
//            // Read and process the audio file in chunks
//            var tot:UInt32 = 0
//            var ctr = 0
//            while inputFile.framePosition < inputFile.length {
//                try inputFile.read(into: inputBuffer!, frameCount: chunkSize)
//                //applyWindow(inputBuffer: inputBuffer!, outputBuffer: outputBuffer!)
//
//                try outputFile.write(from: inputBuffer!)
//                tot += inputBuffer!.frameLength
//                ctr += 1
//            }
//            print("applyHammingWindowToAudioFile sizeOut:", tot, "chunks", ctr, "chunkTimeLen", chunkTimeLen)
//        } catch let error {
//            print(error.localizedDescription)
//        }
//    }

}

//    func fourier() {
//        let numberOfElements = 1000
//        let sineArray1 = getSine(elements: numberOfElements, period: 50.0)
//        let sineArray2 = getSine(elements: numberOfElements, period: 31.0)
//        let sineArray3 = getSine(elements: numberOfElements, period: 77.0)
//
//        var sumArray: [Double] = []
//        for i in 0..<numberOfElements {
//            let sum = sineArray1[i] + sineArray2[i]// + sineArray3[i]
//            sumArray.append(sum)
//        }
//
//        let fourier = self.performFourierTransform(input: sumArray)
//        let fMax = fourier.max()
//        print("Fourier len:", fourier.count, "Max:", fMax ?? 0)
//        var ctr = 0
//        for f in fourier {
//            if f > fMax! * 0.5 {
//                print("index", ctr, "value", f)
//            }
//            ctr += 1
//        }
//
//        DispatchQueue.main.async {
//            self.fourierValues = []
//            self.fourierTransformValues = []
//            for s in sumArray {
//                self.fourierValues.append(s)
//            }
//            for f in fourier {
//                self.fourierTransformValues.append(f)
//            }
//        }
//    }
