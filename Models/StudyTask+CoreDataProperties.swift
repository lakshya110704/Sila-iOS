//
//  StudyTask+CoreDataProperties.swift
//  
//
//  Created by Lakshya Mehta on 07/08/25.
//
//

import Foundation
import CoreData


extension StudyTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudyTask> {
        return NSFetchRequest<StudyTask>(entityName: "StudyTask")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var date: Date?
    @NSManaged public var duration: Int64
    @NSManaged public var subject: String?
    @NSManaged public var title: String?

}
