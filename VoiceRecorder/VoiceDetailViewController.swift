//
//  VoiceDetailViewController.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/5/16.
//  Copyright © 2016 zelig. All rights reserved.
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
    @IBOutlet var tagView: UICollectionView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var playingProgress: UIProgressView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var favoriteButton: UIButton!
    @IBOutlet var exportButton: UIButton!
    
    var sizingCell: TagCellView?

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
            try audioPlayer = AVAudioPlayer(data: voice.audio, fileTypeHint: AVFileTypeAppleM4A)
        } catch {
            print("error initializing AVAudioPlayer: \(error)")
        }

        audioPlayer.prepareToPlay()
        audioPlayer.volume = 0.5
        
        voice.tags?.append("+")
        
        tagView.dataSource = self
        tagView.delegate = self
        
        let cellNib = UINib(nibName: "TagCellView", bundle: nil)
        self.tagView.registerNib(cellNib, forCellWithReuseIdentifier: "TagCell")
        self.tagView.backgroundColor = UIColor.clearColor()
        self.sizingCell = (cellNib.instantiateWithOwner(nil, options: nil) as NSArray).firstObject as! TagCellView?
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

extension VoiceDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return voice.tags!.count
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
        cell.tagLabel.text = voice.tags![indexPath.item]
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if voice.tags![indexPath.item] == "+" {
            var tagTextField: UITextField?
            
            let alertController = UIAlertController(title: "Add TAG", message: nil, preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                if let tagText = tagTextField!.text {
                    self.voice.tags!.insert(tagText, atIndex: self.voice.tags!.count-1)
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
