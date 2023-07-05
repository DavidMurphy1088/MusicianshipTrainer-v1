import Foundation
import FirebaseFirestore
import FirebaseCore

class FirestorePersistance {
    let db = Firestore.firestore()
    
    init() {
    }
    
//    func driveTest() {
//        let driveScope = "https://www.googleapis.com/auth/drive.readonly"
//        let grantedScopes = user.grantedScopes
//        if grantedScopes == nil || !grantedScopes!.contains(driveScope) {
//          // Request additional Drive scope.
//        }
//    }
    
    func test() {
        
        // Get a reference to the Firestore database
        let db = Firestore.firestore()
        
        // Define the collection name you want to read from
        let collectionName = "structure"
        
        // Get a reference to the collection
        let collectionRef = db.collection(collectionName)
        
        // Fetch the documents in the collection
        collectionRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                // Loop through the documents
                for document in querySnapshot!.documents {
                    // Access the data of each document
                    let documentData = document.data()
                    print(documentData)
                    
                    // Process the document data as needed
                    // For example, print the document ID and a specific field
//                    if let documentId = document.documentID,
//                       let fieldValue = documentData["field_name"] as? String {
//                        print("Document ID: \(documentId)")
//                        print("Field value: \(fieldValue)")
//                    }
                }
            }
        }
    }

    
    //func getSyllabus() {
        //print("trying set data...")
        //let collection = "structure"
        //let db = Firestore()
        //let collection = d
//        db.collection(collection).document("LA").setData([
//            "sample": "USA"
//        ]) { err in
//            if let err = err {
//                Logger.logger.reportError(self, "Error writing document", err as NSError)
//            } else {
//                //<<<<<<< HEAD
//                //print("Document successfully written!")
//            }
//        }
        //
        //        //print("trying read data...")
        //=======
        //                print("Document successfully written!")
        //            }
        //        }
        //
        //        print("trying read data...")
        ////>>>>>>> main
        //
        //        db.collection(collection).getDocuments() { (querySnapshot, err) in
        //            if let q = querySnapshot {
        //                for document in q.documents {
        ////<<<<<<< HEAD
        //                    //print(document.description, document.data())
        //                }
        //            }
        //            else {
        //                //print("No documents")
        //=======
        //                    print(document.description, document.data())
        //                }
        //            }
        //            else {
        //                print("No documents")
        //>>>>>>> main
        //            }
        //
        //        }
    //}
}
