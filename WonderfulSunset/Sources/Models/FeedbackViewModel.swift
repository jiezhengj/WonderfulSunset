import Foundation
import SwiftUI
import CoreLocation
import Combine
import CloudKit

class FeedbackViewModel: ObservableObject {
    
    @Published var selectedFeedback: String?
    @Published var selectedFlipReason: String?
    @Published var isSubmitting: Bool = false
    @Published var showSuccess: Bool = false
    @Published var errorMessage: String?
    @Published var hasiCloudAccount: Bool = true
    
    private let cloudKitService = CloudKitService()
    
    init() {
        checkiCloudAccountStatus()
    }
    
    func checkiCloudAccountStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.hasiCloudAccount = true
                case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                    self?.hasiCloudAccount = false
                @unknown default:
                    self?.hasiCloudAccount = false
                }
            }
        }
    }
    
    func submitFeedback(location: CLLocation, predictedScore: Int, feedback: String, flipReason: String? = nil, completion: @escaping () -> Void) {
        isSubmitting = true
        errorMessage = nil
        
        cloudKitService.saveFeedback(
            location: location,
            predictedScore: predictedScore,
            userFeedback: feedback,
            flipReason: flipReason
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSubmitting = false
                
                switch result {
                case .success(_):
                    self?.showSuccess = true
                    // Reset form
                    self?.selectedFeedback = nil
                    self?.selectedFlipReason = nil
                    // Hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showSuccess = false
                        completion()
                    }
                case .failure(let error):
                    self?.errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
                    completion()
                }
            }
        }
    }
    
    func getFlipReasons() -> [String] {
        return ["LowCloud_Block", "Haze_Issue", "No_Color", "Time_Error"]
    }
    
    func getFlipReasonDescription(reason: String) -> String {
        switch reason {
        case "LowCloud_Block":
            return "低云挡住了阳光"
        case "Haze_Issue":
            return "空气太脏/灰蒙蒙"
        case "No_Color":
            return "云太少/没颜色"
        case "Time_Error":
            return "时间对不上"
        default:
            return reason
        }
    }
}