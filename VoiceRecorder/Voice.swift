//
//  Voice.swift
//  VoiceRecorder
//
//  Created by Eddie Cohen & Jason Toff on 8/5/16.
//  Copyright © 2016 zelig. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class Voice: NSManagedObject {
    @NSManaged var title: String?
    @NSManaged var length: NSNumber
    @NSManaged var date: NSDate
    @NSManaged var tags: [String]?
    @NSManaged var location: CLLocation
    @NSManaged var marks: [NSNumber]?
    @NSManaged var audio: NSData
}