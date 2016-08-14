//
//  RecordViewController.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/2/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import UIKit
import AVFoundation
import CloudKit
import CoreLocation

class RecordViewController: UIViewController, UIViewControllerTransitioningDelegate, AVAudioRecorderDelegate, CLLocationManagerDelegate {
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var chevronButton: UIButton!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var titleText: UITextField!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var recordProgress: UIProgressView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var tagView: UICollectionView!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var audioFileURL: NSURL?

    var tags = ["+"]
    var marks = [Int]()
    
    var sizingCell: TagCellView?

    enum RecordState: Int {
        case None
        case OneTime
        case Continuous
        case Pause
        case Done
    }
    
    var recordState: RecordState = RecordState.None
    var recordingTimer: NSTimer!
    var timerCount: Int!
    
    let customPresentAnimationController = CustomPresentAnimationController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinner.hidesWhenStopped = true
        spinner.center = view.center
        view.addSubview(spinner)

        backgroundImage.userInteractionEnabled = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        backgroundImage.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        backgroundImage.addGestureRecognizer(singleTap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        backgroundImage.addGestureRecognizer(longPress)
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        
        getQuickLocationUpdate()
        
        updateUI()
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if !allowed {
                        self.showErrorMessage("You need to configure Microphone permission")
                    }
                }
            }
        } catch {
            showErrorMessage("Failed to configure AVAudioSession!")
        }
        
        tagView.dataSource = self
        tagView.delegate = self
        
        let cellNib = UINib(nibName: "TagCellView", bundle: nil)
        self.tagView.registerNib(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.tagView.backgroundColor = UIColor.clearColor()
        self.sizingCell = (cellNib.instantiateWithOwner(nil, options: nil) as NSArray).firstObject as! TagCellView?
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func handleDelete() {
        if recordState == RecordState.Done {
            tags.removeAll()
            tags.append("+")
            tagView.reloadData()
            marks.removeAll()
            recordState = RecordState.None
            updateUI()
        }
    }
    
    func showErrorMessage(message: String) {
        let alertController = UIAlertController(title: "Error",
                                                message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style:
            UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion:
            nil)
    }
    
    func longPressed(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case UIGestureRecognizerState.Began:
            print("begin long press")
            
            if recordState == RecordState.None {
                startRecording()
                recordState = RecordState.OneTime
                updateUI()
            }
        case .Ended, .Cancelled:
            print("end long press")
            
            if recordState == RecordState.OneTime {
                stopRecording()
                recordState = RecordState.Done
                updateUI()
            }
        default:
            print("other event at long press")
        }
    }
    
    func doubleTapped() {
        print("double tapped")
        
        if recordState == RecordState.None {
            startRecording()
            recordState = RecordState.Continuous
            updateUI()
        }
    }
    
    func singleTapped() {
        print("single tapped")
        
        var newState: RecordState = recordState
        
        switch recordState {
        case RecordState.Continuous:
            audioRecorder.pause()
            recordingTimer.invalidate()
            newState = RecordState.Pause
        case RecordState.Pause:
            marks.append(timerCount)
            audioRecorder.record()
            recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
            timerUpdate()
            newState = RecordState.Continuous
        default: break
        }

        print("old state=\(recordState), new state=\(newState)")
        recordState = newState
        updateUI()
    }
    
    func updateUI() {
        switch recordState {
        case RecordState.None:
            backgroundImage.image = UIImage(named: "blue_background.png")
            recordButton.alpha = 1.0
            chevronButton.alpha = 1.0
            timerLabel.alpha = 0.0
            doneButton.alpha = 0.0
            deleteButton.alpha = 0.0
            titleText.alpha = 0.0
            recordProgress.alpha = 0.0
            tagView.alpha = 0.0
        case RecordState.OneTime, RecordState.Continuous:
            backgroundImage.image = UIImage(named: "red_background.png")
            recordButton.alpha = 0.0
            chevronButton.alpha = 0.0
            timerLabel.alpha = 1.0
            doneButton.alpha = 0.0
            deleteButton.alpha = 0.0
            titleText.alpha = 0.0
            recordProgress.alpha = 1.0
            tagView.alpha = 0.0
        case RecordState.Done:
            backgroundImage.image = UIImage(named: "blue_background.png")
            recordButton.alpha = 0.0
            chevronButton.alpha = 0.0
            timerLabel.alpha = 1.0
            doneButton.alpha = 1.0
            deleteButton.alpha = 1.0
            titleText.alpha = 1.0
            recordProgress.alpha = 1.0
            tagView.alpha = 1.0
        case RecordState.Pause:
            backgroundImage.image = UIImage(named: "red_background.png")
            recordButton.alpha = 0.0
            chevronButton.alpha = 0.0
            timerLabel.alpha = 1.0
            doneButton.alpha = 1.0
            deleteButton.alpha = 1.0
            titleText.alpha = 1.0
            recordProgress.alpha = 1.0
            tagView.alpha = 1.0
        }
    }
    
    func getDocumentsDirectoryURL() -> NSURL {
        let manager = NSFileManager.defaultManager()
        let URLs = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return URLs[0]
    }
    
    func startRecording() {
        audioFileURL = getDocumentsDirectoryURL().URLByAppendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000.0,
            AVNumberOfChannelsKey: 1 as NSNumber,
            AVEncoderAudioQualityKey: AVAudioQuality.High.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: audioFileURL!, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            
            audioRecorder.record()
            
            timerCount = 0
            recordingTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
            timerUpdate()
        } catch {
            abortRecording()
        }
    }
    
    func stopRecording() {
        audioRecorder.stop()
        recordingTimer.invalidate()
        audioRecorder = nil
    }
    
    func abortRecording() {
        audioRecorder.stop()
        recordingTimer.invalidate()
        showErrorMessage("Recorder did finish recording unsuccessfully")
        audioRecorder = nil
        timerCount = 0
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            abortRecording()
            recordState = RecordState.None
            updateUI()
        }
    }
    
    func timerUpdate() {
        timerLabel.text = String(timerCount)
        recordProgress.setProgress(Float(timerCount)/60, animated: false)
        if (timerCount >= 60) {
            audioRecorder.stop()
            audioRecorder = nil
            recordingTimer.invalidate()
            recordState = RecordState.Done
            updateUI()
        }
        timerCount = timerCount + 1
    }
    
    func getQuickLocationUpdate() {
        // Request location authorization
        self.locationManager.requestWhenInUseAuthorization()
        
        // Request a location update
        self.locationManager.requestLocation()
        // Note: requestLocation may timeout and produce an error if authorization has not yet been granted by the user
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Got current location.")
        currentLocation = locations.last
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error while updating location " + error.localizedDescription)
    }
    
    @IBAction func doneTapped() {
        let title = titleText.text
        let length = timerCount
        let tags = self.tags.filter() { $0 != "+" }
        let location = currentLocation!
        let date = NSDate()
        let marks = self.marks
        let audio = audioFileURL!
        
        let voice = Voice(title: title, length: length, date: date, tags: tags, location: location, marks: marks, audio: audio)
        
        saveRecordToCloud(voice)
    }
    
    // MARK: - CloudKit Methods
    
    func saveRecordToCloud(voice: Voice) -> Void {
        spinner.startAnimating()
        
        // Prepare the record to save
        let record = CKRecord(recordType: "Voice")
        record.setValue(voice.title, forKey: "title")
        record.setValue(voice.length, forKey: "length")
        record.setValue(voice.tags, forKey: "tags")
        record.setValue(voice.location, forKey: "location")
        record.setValue(voice.marks, forKey: "marks")
        record.setValue(voice.date, forKey: "date")
        
        // Create audio asset for upload
        let audioAsset = CKAsset(fileURL: voice.audio)
        record.setValue(audioAsset, forKey: "audio")
        
        // Get the Public iCloud Database
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        // Save the record to iCloud
        publicDatabase.saveRecord(record, completionHandler: { (record:CKRecord?, error:NSError?) -> Void  in
            if (error == nil) {
                // Remove temp file
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(voice.audio.path!)
                    print("Saved record to the cloud.")

                    NSOperationQueue.mainQueue().addOperationWithBlock() {
                        self.spinner.stopAnimating()
                        self.performSegueWithIdentifier("doneRecording", sender: self)
                    }
                } catch {
                    print("Failed to delete temparary file.")
                }
            } else {
                print("Failed to save record to the cloud: \(error)")
            }
        })
    }
}

extension RecordViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let tagCell = collectionView.dequeueReusableCellWithReuseIdentifier("TagCell", forIndexPath: indexPath) as! TagCellView
        self.configureCell(tagCell, forIndexPath: indexPath)
        return tagCell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        self.configureCell(self.sizingCell!, forIndexPath: indexPath)
        return self.sizingCell!.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
    }
    
    func configureCell(cell: TagCellView, forIndexPath indexPath: NSIndexPath) {
        cell.tagLabel.text = tags[indexPath.item]
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if tags[indexPath.item] == "+" {
            var tagTextField: UITextField?
            
            let alertController = UIAlertController(title: "Add TAG", message: nil, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                if let tagText = tagTextField!.text {
                    self.tags.insert(tagText, atIndex: self.tags.count-1)
                    self.tagView.reloadData()
                }
            })
            let cancel = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            alertController.addAction(ok)
            alertController.addAction(cancel)
            alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
                tagTextField = textField
                tagTextField!.placeholder = "TAG"
            }
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
}
