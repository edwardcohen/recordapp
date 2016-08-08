//
//  VoiceDetailViewController.swift
//  VoiceRecorder
//
//  Created by developer on 8/5/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import MapKit

class VoiceDetailViewController: UIViewController, AVAudioPlayerDelegate {

    var voice: Voice!
    
    var audioPlayer: AVAudioPlayer!
    
    var timer: NSTimer?
    
    @IBOutlet var titleText: UITextField!
    @IBOutlet var lengthLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var playingProgress: UIProgressView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var favoriteButton: UIButton!
    @IBOutlet var exportButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleText.text = voice.title
        lengthLabel.text = String(voice.length)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = voice.location.coordinate
        mapView.showAnnotations([annotation], animated: true)
        mapView.selectAnnotation(annotation, animated: true)
        
        do {
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try! AVAudioSession.sharedInstance().setActive(true)
            try audioPlayer = AVAudioPlayer(contentsOfURL: voice.audio, fileTypeHint: AVFileTypeAppleM4A)
        } catch {
            print("error initializing AVAudioPlayer: \(error)")
        }

        audioPlayer.prepareToPlay()
        audioPlayer.volume = 0.5
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playVoice() {
        audioPlayer.play()
        startTimer()
        audioPlayer.delegate = self
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer.stop()
        timer?.invalidate()
    }
    
    func startTimer() {
        timer = NSTimer(timeInterval: 0.1, target: self, selector: #selector(VoiceDetailViewController.updateProgress), userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: "NSDefaultRunLoopMode")
    }
    
    func updateProgress() {
        audioPlayer.updateMeters()
        playingProgress.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
