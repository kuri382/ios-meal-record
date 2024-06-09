import Foundation
import MessageUI
import SwiftUI

class EmailManager: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = EmailManager()
    
    func generateCSVData(for images: [String: [ImageData]], users: [User], facilityName: String) -> String {
        var csvString = "施設名,記録日時,氏名,主食の残食率,副食の残食率\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        
        for user in users {
            guard let userImages = images[user.id], let latestImage = userImages.first else {
                continue
            }
            
            let formattedDate = dateFormatter.string(from: Date(timeIntervalSince1970: latestImage.submittedAt / 1000))
            
            let stapleAverage = calculateAverage(for: latestImage.meals, label: "staple")
            let sideAverage = calculateAverage(for: latestImage.meals, label: "side")
            
            let line = "\(facilityName),\(formattedDate),\(user.userName),\(stapleAverage),\(sideAverage)\n"
            csvString += line
        }
        
        return csvString
    }
    
    private func calculateAverage(for meals: [Meal]?, label: String) -> Double {
        guard let meals = meals else { return 0.0 }
        let filteredMeals = meals.filter { $0.label == label }
        let totalRemaining = filteredMeals.reduce(0.0) { $0 + $1.remaining }
        return filteredMeals.isEmpty ? 0.0 : (totalRemaining / Double(filteredMeals.count)) * 100
    }
    
    func sendEmail(csvData: String, facilityName: String, presentingViewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            print("Mail services are not available")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        composeVC.setSubject("食事記録 \(dateString)")
        composeVC.setMessageBody("選択した施設と日付のユーザーごとのデータを添付します。", isHTML: false)
        
        let attachmentData = csvData.data(using: .utf8)!
        composeVC.addAttachmentData(attachmentData, mimeType: "text/csv", fileName: "\(facilityName)_\(dateString).csv")
        
        presentingViewController.present(composeVC, animated: true, completion: nil)
    }
    
    // MFMailComposeViewControllerDelegate method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
