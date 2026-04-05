//
//  ViewController.swift
//  火柴游戏
//
//  Created by muzi li on 2026/3/28.
//

import UIKit

import SwiftUI

class AppOrientation {
    static let shared = AppOrientation()
    var isLandscapeLocked = false
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hostingController = UIHostingController(
            rootView: MainTabView()
                .environmentObject(AppProgressStore.shared)
                .environmentObject(PoemSpeechService.shared)
        )
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if AppOrientation.shared.isLandscapeLocked {
            return .landscape
        }
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}

