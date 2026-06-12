//
//  DeeplinkTarget.swift
//  mobile
//
//  Created by Joon Lee on 12/16/25.
//

enum DeeplinkTarget: Identifiable, Hashable {
    case main
    case session(workoutFile: String? = nil)
    case calendar
    case library

    var id: Self { self }
}

