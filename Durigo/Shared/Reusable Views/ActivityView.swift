//
//  ActivityView.swift
//  Durigo
//
//  Created by Joshua Cardozo on 19/11/23.
//

import SwiftUI

#if canImport(UIKit)
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        controller.excludedActivityTypes = [.sharePlay, .saveToCameraRoll, .postToWeibo, .postToVimeo, .postToTwitter, .postToTencentWeibo, .postToFlickr, .postToFacebook, .openInIBooks, .message, .markupAsPDF, .mail, .copyToPasteboard, .collaborationInviteWithLink, .collaborationCopyLink, .assignToContact, .addToReadingList]
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
