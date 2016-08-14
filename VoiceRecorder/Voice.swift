//
//  Voice.swift
//  VoiceRecorder
//
//  Created by developer on 8/5/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import CoreLocation

class Voice {
    var title: String?
    var length: Int
    var date: NSDate
    var tags: [String]?
    var location: CLLocation
    var marks: [Int]?
    var audio: NSURL

    init(title: String?, length: Int, date: NSDate, tags: [String]?, location: CLLocation, marks: [Int]?, audio: NSURL) {
        self.title = title
        self.length = length
        self.date = date
        self.tags = tags
        self.location = location
        self.marks = marks
        self.audio = audio
    }
}