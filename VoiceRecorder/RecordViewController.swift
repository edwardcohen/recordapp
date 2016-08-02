//
//  RecordViewController.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/2/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, UIViewControllerTransitioningDelegate, AVAudioRecorderDelegate {
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var chevronButton: UIButton!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var titleText: UITextField!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var recordProgress: UIProgressView!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!

    enum RecordingMode: Int {
        case None
        case OneTime
        case Continuous
        case Pause
        case Done
    }
    
    var recordingMode: RecordingMode = RecordingMode.None
    var recordingTimer: NSTimer!
    var timerCount: Int!
    
    let customPresentAnimationController = CustomPresentAnimationController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        recordButton.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        view.addGestureRecognizer(singleTap)

        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneRecording" {
            finishRecording()
        }
    }

//    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return customPresentAnimationController
//    }
    
    func showErrorMessage(message: String) {
        let alertController = UIAlertController(title: "Error",
                                                message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style:
            UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion:
            nil)
    }
    
    func doubleTapped() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if allowed {
                        self.recordingMode = RecordingMode.Continuous
                        self.updateUI()
                        self.startRecording()
                    } else {
                        self.showErrorMessage("You need to configure Microphone permission")
                    }
                }
            }
        } catch {
            showErrorMessage("Failed to configure AVAudioSession!")
        }

    }
    
    func singleTapped() {
        var nextState: RecordingMode = recordingMode
        
        switch recordingMode {
        case RecordingMode.None:
            print("old state=None, next state=None")
        case RecordingMode.OneTime:
            print("old state=OneTime, next state=OneTime")
        case RecordingMode.Continuous:
            audioRecorder.pause()
            recordingTimer.invalidate()
            nextState = RecordingMode.Pause
        case RecordingMode.Pause:
            audioRecorder.record()
            recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
            timerUpdate()
            nextState = RecordingMode.Continuous
        case RecordingMode.Done:
            print("old state=Done, next state=Done")
        }

        recordingMode = nextState
        updateUI()
    }
    
    func updateUI() {
        switch recordingMode {
        case RecordingMode.None:
            backgroundImage.image = UIImage(named: "blue_background.png")
            recordButton.alpha = 1.0
            chevronButton.alpha = 1.0
            timerLabel.alpha = 0.0
            doneButton.alpha = 0.0
            deleteButton.alpha = 0.0
            titleText.alpha = 0.0
            recordProgress.alpha = 0.0
        case RecordingMode.OneTime, RecordingMode.Continuous:
            backgroundImage.image = UIImage(named: "red_background.png")
            recordButton.alpha = 0.0
            chevronButton.alpha = 0.0
            timerLabel.alpha = 1.0
            doneButton.alpha = 0.0
            deleteButton.alpha = 0.0
            titleText.alpha = 0.0
            recordProgress.alpha = 1.0
        case RecordingMode.Done:
            backgroundImage.image = UIImage(named: "blue_background.png")
            recordButton.alpha = 0.0
            chevronButton.alpha = 0.0
            timerLabel.alpha = 1.0
            doneButton.alpha = 1.0
            deleteButton.alpha = 1.0
            titleText.alpha = 1.0
            recordProgress.alpha = 1.0
        case RecordingMode.Pause:
            backgroundImage.image = UIImage(named: "red_background.png")
            recordButton.alpha = 0.0
            chevronButton.alpha = 0.0
            timerLabel.alpha = 1.0
            doneButton.alpha = 1.0
            deleteButton.alpha = 1.0
            titleText.alpha = 1.0
            recordProgress.alpha = 1.0
        }
    }
    
    func startRecording() {
        let audioFileURL = getDocumentsDirectoryURL().URLByAppendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: audioFileURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            timerCount = 0
            recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
            timerUpdate()
        } catch {
            abortRecording()
        }
    }
    
    func getDocumentsDirectoryURL() -> NSURL {
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return URLs[0]
    }
    
    func finishRecording() {

    }
    
    func abortRecording() {
        audioRecorder.stop()
        recordingTimer.invalidate()
        showErrorMessage("Recorder did finish recording unsuccessfully")
        audioRecorder = nil
        timerCount = 0
        recordingMode = RecordingMode.None
        updateUI()
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            abortRecording()
        }
    }
    
    func timerUpdate() {
        timerLabel.text = String(timerCount)
        recordProgress.setProgress(Float(timerCount)/60, animated: false)
        if (timerCount >= 60) {
            audioRecorder.stop()
            audioRecorder = nil
            recordingTimer.invalidate()
            recordingMode = RecordingMode.Done
            updateUI()
        }
        timerCount = timerCount + 1
    }
    
}

