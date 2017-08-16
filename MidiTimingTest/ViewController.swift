//
//  ViewController.swift
//  MidiTimingTest
//
//  Created by David O'Neill on 8/15/17.
//  Copyright © 2017 O'Neill. All rights reserved.
//

import UIKit
import AudioKit
import AVFoundation



class ViewController: UIViewController {


    var mixer = AKMixer()
    var cMixer = AKMixer()
    var avMixer = AKMixer()
    var sampler: AVAudioUnit!
    var akMidiSampler = AKMIDISampler()
    var testSequencer = TestSequencer()
    var mic = AKMicrophone()
    var cRecorder: AKNodeRecorder?
    var avRecorder: AKNodeRecorder?
    var sequencer = AKSequencer()

    override func viewDidLoad() {
        super.viewDidLoad()

        var mixerDesc = AudioComponentDescription()
        mixerDesc.componentType = kAudioUnitType_MusicDevice
        mixerDesc.componentSubType = kAudioUnitSubType_Sampler
        mixerDesc.componentManufacturer = kAudioUnitManufacturer_Apple




        AVAudioUnit.instantiate(with: mixerDesc, options: .loadOutOfProcess, completionHandler: { (avAudioUnit, error) in
            guard let avAudioUnit = avAudioUnit else { fatalError() }
            self.sampler = avAudioUnit
        });
        AudioKit.engine.attach(sampler)

        guard let track = sequencer.newTrack() else {
            fatalError()
        }



        sampler >>> cMixer >>> mixer
        akMidiSampler >>> avMixer >>> mixer


        sequencer.setTempo(60)

        track.setMIDIOutput(akMidiSampler.midiIn)
        for i in 0..<8 {
            track.add(noteNumber: 64, velocity: 127, position: AKDuration.init(beats: i * 0.25), duration: AKDuration.init(beats: 0.1))
        }


        AudioKit.output = mixer
        AudioKit.start()

        testSequencer.setRenderNotify(sampler.audioUnit)
        var cURL: URL!
        var avURL: URL!
        do {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let format = AVAudioFormat.init(commonFormat: .pcmFormatInt16,
                                            sampleRate: AudioKit.format.sampleRate,
                                            channels: 2,
                                            interleaved: true)


            cURL = docs.appendingPathComponent("c.caf")
            let cAudioFile = try AKAudioFile.init(forWriting: cURL, settings: format.settings)
            cRecorder = try AKNodeRecorder.init(node: cMixer, file: cAudioFile)


            avURL = docs.appendingPathComponent("av.caf")
            let avAudioFile = try AKAudioFile.init(forWriting: avURL, settings: format.settings)
            avRecorder = try AKNodeRecorder.init(node: avMixer, file: avAudioFile)


            try avRecorder?.record()
            try cRecorder?.record()

        } catch {
            fatalError(String(describing: error))
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            self.sequencer.play()
            self.testSequencer.start()
        }


        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.cRecorder?.stop()
            self.avRecorder?.stop()
            print("Copy this to get files from the simulator to ~/Downloads\n\n")
            print("cp " + cURL.path + " " + avURL.path + " ~/Downloads")
        }

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

