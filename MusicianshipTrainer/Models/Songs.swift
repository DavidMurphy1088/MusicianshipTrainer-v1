
import Foundation

class Songs {
    func song(base:Note, interval:Int) -> (String?, [Note]) {
        var notes : [Note] = []
        let first = base.midiNumber
        var name:String? = nil
        // https://www.earmaster.com/products/free-tools/interval-song-chart-generator.html
        // duration 1 = 16th note
        
        //missing: minor second

        if interval == 2 {
            name = "Happy Birthday"
            notes.append(Note(num: first + 0, value: 2))
            notes.append(Note(num: first + 0, value: 2))
            
            notes.append(Note(num: first + 2, value: 4))
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first + 5, value: 4))
            
            notes.append(Note(num: first + 4, value: 8))
        }
        
        if interval == -2 {
            name = "Mary Had A Little Lamb"
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first - 2, value: 4))
            notes.append(Note(num: first - 4, value: 4))
            notes.append(Note(num: first - 2, value: 4))
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first + 0, value: 4))
        }
        
        if interval == 3 { //minor third
            name = "Greensleeves"
            notes.append(Note(num: first + 0, value: 2))
            
            notes.append(Note(num: first + 3, value: 4))
            notes.append(Note(num: first + 5, value: 2))

            notes.append(Note(num: first + 7, value: 3))
            notes.append(Note(num: first + 8, value: 1))
            notes.append(Note(num: first + 7, value: 2))
            
            notes.append(Note(num: first + 5, value: 4))
            notes.append(Note(num: first + 2, value: 2))
            notes.append(Note(num: first - 2, value: 1))
        }
        
        if interval == -3 {
            name = "Hey Jude"
            notes.append(Note(num: first + 0, value: 4))
            
            notes.append(Note(num: first - 3, value: 9))
            notes.append(Note(num: first - 3, value: 2))
            notes.append(Note(num: first + 0, value: 2))
            notes.append(Note(num: first + 2, value: 2))
            
            notes.append(Note(num: first - 5, value: 4))
        }
        
        if interval == 4 {
            name = "When The Saints Go Marching In"
            notes.append(Note(num: first + 0, value: 2))
            
            notes.append(Note(num: first + 4, value: 2))
            notes.append(Note(num: first + 5, value: 2))
            notes.append(Note(num: first + 7, value: 4))
        }
 
        if interval == -4 {
            name = "Swing Low, Sweet Chariot"
            notes.append(Note(num: first + 0, value: 4))
            
            notes.append(Note(num: first - 4, value: 12))
            notes.append(Note(num: first + 0, value: 4))
            
            notes.append(Note(num: first - 4, value: 6))
            notes.append(Note(num: first - 4, value: 1))
            notes.append(Note(num: first - 7, value: 2))
            notes.append(Note(num: first - 9, value: 6))
        }
        
        if interval == 5 {
            name = "Amazing Grace"
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first + 5, value: 8))
            notes.append(Note(num: first + 9, value: 3))
            notes.append(Note(num: first + 5, value: 1))
            notes.append(Note(num: first + 9, value: 8))
        }

        if interval == -5 {
            name = "O Come, All Ye Faithful"
            notes.append(Note(num: first + 0, value: 4))
            
            notes.append(Note(num: first + 0, value: 8))
            notes.append(Note(num: first - 5, value: 4))
            notes.append(Note(num: first + 0, value: 4))
            
            notes.append(Note(num: first + 2, value: 8))
            notes.append(Note(num: first - 5, value: 8))
        }
        
        //missing: tritone
        
        if interval == 7 {
            name = "Twinkle Twinkle Little Star"
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first + 7, value: 4))
            notes.append(Note(num: first + 7, value: 4))
            notes.append(Note(num: first + 9, value: 4))
            notes.append(Note(num: first + 9, value: 4))
            notes.append(Note(num: first + 7, value: 4))
        }
        
        if interval == -7 {
            name = "Flintones, Meet The Flintstones"
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first - 7, value: 8))
            
            notes.append(Note(num: first + 5, value: 4))
            notes.append(Note(num: first + 2, value: 2))
            
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first - 7, value: 6))
        }
        
        if interval == -8 {
            name = "Love Story Theme"
            notes.append(Note(num: first + 0, value: 2))
            notes.append(Note(num: first - 8, value: 2))
            notes.append(Note(num: first - 8, value: 2))
            notes.append(Note(num: first + 0, value: 2))

            notes.append(Note(num: first + 0, value: 8))
            notes.append(Note(num: first - 8, value: 2))
            notes.append(Note(num: first - 8, value: 2))
            notes.append(Note(num: first + 0, value: 2))

        }
        if interval == 8 {
            name = "Mozart Requiem Lacrimosa"
            notes.append(Note(num: first + 0, value: 8))
            notes.append(Note(num: first + 8, value: 2))
            notes.append(Note(num: first + 5, value: 2))
            
            notes.append(Note(num: first + 5, value: 6))
            notes.append(Note(num: first + 4, value: 8))
        }
        
        if interval == 9 {
            name = "My Bonnie Lies Over the Ocean"
            notes.append(Note(num: first + 0, value: 4))
            
            notes.append(Note(num: first + 9, value: 6))
            notes.append(Note(num: first + 7, value: 2))
            notes.append(Note(num: first + 5, value: 4))
            
            notes.append(Note(num: first + 7, value: 4))
            notes.append(Note(num: first + 5, value: 4))
            notes.append(Note(num: first + 2, value: 4))
            
            notes.append(Note(num: first + 0, value: 4))
            notes.append(Note(num: first - 3, value: 8))
            //notes.append(Note(num: first - 5, value: 8))

        }
        if interval == -9 {
            name = "Nobody Knows The Trouble I've Seen"
            notes.append(Note(num: first + 0, value: 2))
            notes.append(Note(num: first - 9, value: 4))
            
            notes.append(Note(num: first - 7, value: 2))
            notes.append(Note(num: first - 4, value: 6))

            notes.append(Note(num: first - 2, value: 2))
            notes.append(Note(num: first + 0, value: 4))


        }
        if interval == 10 {
            name = "Somewhere - West Side Story"
            notes.append(Note(num: first + 0, value: 8))
            notes.append(Note(num: first + 10, value: 8))
            
            notes.append(Note(num: first + 8, value: 6))
            notes.append(Note(num: first + 5, value: 2))
            notes.append(Note(num: first + 2, value: 8))

        }

        //missing: min 7th descending
        
        if interval == 11 {
            name = "Somewhere Over The Rainbow"
            notes.append(Note(num: first + 0, value: 8))
            notes.append(Note(num: first + 12, value: 8))
            
            notes.append(Note(num: first + 11, value: 12)) //1st and 3rd pitch only
            notes.append(Note(num: first + 7, value: 2))
            notes.append(Note(num: first + 9, value: 2))
            notes.append(Note(num: first + 11, value: 4))
            notes.append(Note(num: first + 12, value: 8))
        }
        
        //missing: maj 7th descending
        return (name, notes)
    }
}
