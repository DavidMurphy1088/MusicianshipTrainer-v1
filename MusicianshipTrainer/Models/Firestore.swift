import Foundation
import FirebaseFirestore
import FirebaseCore

class FirestorePersistance {
    let db = Firestore.firestore()
    
    init() {
    }
    
    func driveTest() {
        let x = "https://docs.google.com/document/d/1X8EKKTL9tkNf687opYxqXZUxYf9H3yt67lSod8ZbOIQ/edit?usp=sharing"
        guard let url = URL(string: x) else {
            print("Invalid URL")
            return
        }

        // Create a URLSession instance
        let session = URLSession.shared

        // Create a data task to perform the request
        let task = session.dataTask(with: url) { (data, response, error) in
            // Handle the response or error
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Status code: \(httpResponse.statusCode)")
                
                if let data = data {
                    // Process the response data
                    let responseString = String(data: data, encoding: .utf8)
                    print("Response: \(responseString ?? "")")
                }
            }
        }

        // Start the task
        task.resume()
    }
    
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
