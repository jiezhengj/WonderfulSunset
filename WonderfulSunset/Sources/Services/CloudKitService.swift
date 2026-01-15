import Foundation
import CloudKit
import CoreLocation

class CloudKitService {
    private let container = CKContainer.default()
    private let publicDatabase = CKContainer.default().publicCloudDatabase
    
    func saveFeedback(location: CLLocation, predictedScore: Int, userFeedback: String, flipReason: String? = nil, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Blur location to 0.1 degree precision
        let blurredLat = Double(round(10 * location.coordinate.latitude) / 10)
        let blurredLon = Double(round(10 * location.coordinate.longitude) / 10)
        let blurredLocation = CLLocation(latitude: blurredLat, longitude: blurredLon)
        
        let record = CKRecord(recordType: "GlobalFeedback")
        record["Location"] = blurredLocation
        record["PredictedScore"] = predictedScore
        record["UserFeedback"] = userFeedback
        record["FlipReason"] = flipReason
        record["Timestamp"] = Date()
        
        publicDatabase.save(record) { (record, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    func getFeedback(for location: CLLocation, radius: CLLocationDistance = 50000, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "GlobalFeedback", predicate: predicate)
        
        publicDatabase.fetch(withQuery: query, inZoneWith: nil) { result in
            switch result {
            case .success(let (matchResults, _)):
                // Extract successful records from matchResults
                let records = matchResults.compactMap { (_, result) in
                    switch result {
                    case .success(let record):
                        return record
                    case .failure:
                        return nil
                    }
                }
                
                // Filter records within specified radius
                let filteredRecords = records.filter { record in
                    if let recordLocation = record["Location"] as? CLLocation {
                        return location.distance(from: recordLocation) <= radius
                    }
                    return false
                }
                completion(.success(filteredRecords))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}