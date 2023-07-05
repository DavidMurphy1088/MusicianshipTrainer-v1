//import SwiftUI
//import CoreData
//import MessageUI
//
//class NoteLayout {
//    var note:Note
//    var stemLength:Double = 1.0
//    var stemDirection = 1
//    var quaverBeam:QuaverBeamType = QuaverBeamType.none
//    var quaverBeamAngle:Double = 0.0
//    
//    init(note:Note, pos:CGRect?=nil) {
//        self.note = note
//    }
//}
//
////class NotePositions : ObservableObject  {
////
////    //Return the note stem characteristics for a note in the staff. Notes cannot know their own stem lengths or directions since thay may be under quaver beams
////    func getLayout(note:Note) -> NoteLayout {
////        let notePos = NoteLayout(note: note)
//////        if let pos = notePositions[note] {
//////            notePos.pos = pos
//////        }
////        if note.isOnlyRhythmNote {
////            notePos.stemDirection = 1
////        }
////        else {
////            notePos.stemDirection = note.midiNumber > 71 ? -1 : 1
////        }
////        notePos.stemLength = 1.0
////        notePos.quaverBeam = note.beamType
////        if note.beamType == .start {
////            notePos.quaverBeamAngle = note.beamEndNote!.midiNumber > note.midiNumber ? -20 : 20
////        }
////        if note.beamType == .end {
////            notePos.quaverBeamAngle = note.beamEndNote!.midiNumber > note.midiNumber ? 20 : -20
////        }
////        return notePos
////    }
////}
////
//
