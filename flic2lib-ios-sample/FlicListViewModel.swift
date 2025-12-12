//
//  FlicViewModel.swift
//  flic2lib-ios-sample
//
//  Created by Oskar Öberg on 2024-02-09.
//

import Foundation
import flic2lib

class FlicButtonModel: ObservableObject, Identifiable {
	let flicButton: FLICButton
	var isDuo:Bool {
		return self.flicButton.serialNumber.hasPrefix("D")
	}
	
	@Published var downButtons: Set<UInt8> = []
	
	init(_ flicButton: FLICButton) {
		self.flicButton = flicButton
	}
}

class FlicListViewModel: NSObject, ObservableObject, FLICButtonDelegate, FLICManagerDelegate {
    
    @Published var buttons: [FlicButtonModel] = []
    @Published var promptToRemoveButton: Bool = false
    @Published var buttonToBeRemoved: FlicButtonModel?
    @Published var isScanning: Bool = false
    @Published var scanState: FLICButtonScannerStatusEvent? = nil
    
    override convenience init() {
        self.init(isPreview: false)
    }
    
    init(isPreview: Bool) {
        super.init()
        if !isPreview {
            FLICManager.configure(with: self, buttonDelegate: self, background: true)
        }
    }

    // MARK: - FLICButtonDelegate
    
    func buttonDidConnect(_ flicButton: FLICButton) {
        print("buttonDidConnect")
    }
    
    func buttonIsReady(_ button: FLICButton) {
        print("buttonIsReady")
        reloadButtons()
    }
    
    func button(_ flicButton: FLICButton, didDisconnectWithError error: Error?) {
        print("didDisconnectWithError", error ?? "")
		self.buttons = self.buttons
    }
    
    func button(_ flicButton: FLICButton, didReceive buttonEvent: FLICButtonEvent) {
        print("didReceiveButtonEvent", buttonEvent)
        
        buttonEvent.isGesture { gesture, buttonNumber in
            print("gesture detected on button \(buttonNumber): \(gesture)")
        }
        
        buttonEvent.isSingleOrDoubleClickOrHold { type, buttonNumber in
            print("\(type) on button \(buttonNumber)")
        }
        
        if buttonEvent.eventClass == .upOrDown {
			if let button = buttons.first(where: { $0.flicButton == flicButton }) {
				if (buttonEvent.type == .down) {
					button.downButtons.insert(buttonEvent.buttonNumber)
				} else {
					button.downButtons.remove(buttonEvent.buttonNumber)
				}
            }
        }
    }
    
    func button(_ button: FLICButton, didFailToConnectWithError error: Error?) {
        print("didFailToConnectWithError", error ?? "")
    }
    
    // MARK: - FLICManagerDelegate
    
    func managerDidRestoreState(_ manager: FLICManager) {
        print("managerDidRestoreState")
        reloadButtons()
    }
    
    func manager(_ manager: FLICManager, didUpdate state: FLICManagerState) {
        print("managerDidUpdate")
    }
    
    // MARK: - Helpers
    
    func reloadButtons() {
        DispatchQueue.main.async {
            var newButtons: [FlicButtonModel] = []
            if let manager = FLICManager.shared() {
                for flicButton in manager.buttons() {
                    newButtons.append(FlicButtonModel(flicButton))
                }
            }
            self.buttons = newButtons
        }
    }
    
    func removeButton(_ button: FlicButtonModel) {
		Task {
			defer {
				reloadButtons()
			}
			
			do {
				try await FLICManager.shared()?.forgetButton(button.flicButton)
			} catch {
				print("Failed to forget button: \(error)")
			}
		}
    }
    
    @Published var scanError: String? = nil

    func scan() {
        scanState = nil
        isScanning = true
        scanError = nil
        FLICManager.shared()?.scanForButtons(stateChangeHandler: { event in
            print(event)
            self.scanState = event
        }, completion: { button, error in
            self.isScanning = false
            if let error = error {
                self.scanError = error.localizedDescription
            }
        })
    }
}
