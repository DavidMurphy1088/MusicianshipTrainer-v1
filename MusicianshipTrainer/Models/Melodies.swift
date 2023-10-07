
import Foundation

class Melody : Identifiable {
    let id = UUID()
    let halfSteps:Int
    let name:String
    var notes:[Note]
    
    init (halfSteps:Int, name:String) {
        self.name = name
        self.halfSteps = halfSteps
        self.notes = []
    }
    
    func transpose(base:Note) -> [Note] {
        var result:[Note] = []
        let firstPitch = notes[0].midiNumber
        let delta = firstPitch - base.midiNumber
        for n in notes {
            result.append(Note(timeSlice: nil, num: n.midiNumber - delta, value: n.getValue(), staffNum: 0))
        }
        return result
    }
}

class Melodies {
    static public let shared = Melodies()
    var melodies:[Melody] = []
    
    func addMelody(melody:Melody) {
        self.melodies.append(melody)
    }
    
    ///Return a list of melodies for the given interval
    func getMelodies(halfSteps:Int) -> [Melody] {
        var melodies : [Melody] = []
        for melody in self.melodies {
            if melody.halfSteps == halfSteps {
                melodies.append(melody)
            }
        }
        return melodies
    }
    
    func song1(timeSlice:TimeSlice, base:Note, interval:Int) -> (String?, [Note]) {
        var notes : [Note] = []
        let first = base.midiNumber
        var name:String? = nil
        // https://www.earmaster.com/products/free-tools/interval-song-chart-generator.html
        // duration 1 = 16th note
        
        //missing: minor second
        let staffNum = 0
        if interval == 2 {
            name = "Happy Birthday"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 4, value: 8, staffNum: staffNum))
        }
        
        if interval == -2 {
            name = "Mary Had A Little Lamb"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 2, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 4, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 2, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
        }
        
        if interval == 3 { //minor third
            name = "Greensleeves"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 3, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 2, staffNum: staffNum))

            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 3, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 8, value: 1, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 2, value: 1, staffNum: staffNum))
        }
        
        if interval == -3 {
            name = "Hey Jude"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first - 3, value: 9, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 3, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first - 5, value: 4, staffNum: staffNum))
        }
        
        if interval == 4 {
            name = "When The Saints Go Marching In"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 4, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 4, staffNum: staffNum))
        }
 
        if interval == -4 {
            name = "Swing Low, Sweet Chariot"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first - 4, value: 12, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first - 4, value: 6, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 4, value: 1, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 7, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 9, value: 6, staffNum: staffNum))
        }
        
        if interval == 5 {
            name = "Amazing Grace"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 9, value: 3, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 1, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 9, value: 8, staffNum: staffNum))
        }

        if interval == -5 {
            name = "O Come, All Ye Faithful"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 5, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 5, value: 8, staffNum: staffNum))
        }
        
        //missing: tritone
        
        if interval == 7 {
            name = "Twinkle Twinkle Little Star"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 9, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 9, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 4, staffNum: staffNum))
        }
        
        if interval == -7 {
            name = "Flintones, Meet The Flintstones"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 7, value: 8, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 7, value: 6, staffNum: staffNum))
        }
        
        if interval == -8 {
            name = "Love Story Theme"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 8, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 8, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))

            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 8, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 8, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))

        }
        if interval == 8 {
            name = "Mozart Requiem Lacrimosa"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 8, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 2, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 6, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 4, value: 8, staffNum: staffNum))
        }
        
        if interval == 9 {
            name = "My Bonnie Lies Over the Ocean"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 9, value: 6, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 3, value: 8, staffNum: staffNum))
            //notes.append(Note(timeSlice:timeSlice, num: first - 5, value: 8))

        }
        if interval == -9 {
            name = "Nobody Knows The Trouble I've Seen"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 9, value: 4, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first - 7, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first - 4, value: 6, staffNum: staffNum))

            notes.append(Note(timeSlice:timeSlice, num: first - 2, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 4, staffNum: staffNum))


        }
        if interval == 10 {
            name = "Somewhere - West Side Story"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 10, value: 8, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 8, value: 6, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 5, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 2, value: 8, staffNum: staffNum))

        }

        //missing: min 7th descending
        
        if interval == 11 {
            name = "Somewhere Over The Rainbow"
            notes.append(Note(timeSlice:timeSlice, num: first + 0, value: 8, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 12, value: 8, staffNum: staffNum))
            
            notes.append(Note(timeSlice:timeSlice, num: first + 11, value: 12, staffNum: staffNum)) //1st and 3rd pitch only
            notes.append(Note(timeSlice:timeSlice, num: first + 7, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 9, value: 2, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 11, value: 4, staffNum: staffNum))
            notes.append(Note(timeSlice:timeSlice, num: first + 12, value: 8, staffNum: staffNum))
        }
        
        //missing: maj 7th descending
        return (name, notes)
    }
}
