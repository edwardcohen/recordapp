//
//  Voice.swift
//  VoiceRecorder
//
//  Created by developer on 8/5/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import CoreLocation
import CoreData

class Voice: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var tags: [String]?
    @NSManaged var marks: [Int]?
    @NSManaged var length: NSNumber
    @NSManaged var date: NSDate
    @NSManaged var location: CLLocation
    @NSManaged var audio: NSURL

//    init(title: String?, length: Int, date: NSDate, tags: [String]?, location: CLLocation, marks: [Int]?, audio: NSURL) {
//        self.title = title
//        self.length = length
//        self.date = date
//        self.tags = tags
//        self.location = location
//        self.marks = marks
//        self.audio = audio
//    }
}