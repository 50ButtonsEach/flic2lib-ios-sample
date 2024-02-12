//
//  ContentView.swift
//  flic2lib-ios-sample
//
//  Created by Oskar Öberg on 2024-02-09.
//

import SwiftUI
import flic2lib

class ViewModel : NSObject, ObservableObject, FLICButtonDelegate, FLICManagerDelegate {
	
	@Published var buttons: [Button] = []
	@Published var promptToRemoveButton: Bool = false
	@Published var buttonToBeRemoved: Button?
	@Published var isScanning: Bool = false
	@Published var scanState: FLICButtonScannerStatusEvent? = nil
	
	struct Button {
		let identifier: UUID
		var name: String?
		var pushed: Bool = false
		var connected: Bool = false
		
		init(_ flicButton: FLICButton) {
			self.identifier = flicButton.identifier
			self.name = flicButton.name
			self.connected = flicButton.state == .connected
		}
		
		init(identifier: UUID, name: String?) {
			self.identifier = identifier
			self.name = name
		}
	}
	
	override convenience init() {
		self.init(preview: false)
	}
	
	init(preview: Bool) {
		super.init()
		if (!preview) {
			FLICManager.configure(with:self, buttonDelegate: self, background: true)
		}
	}

	func buttonDidConnect(_ flicButton: FLICButton) {
		print("buttonDidConnect")
		if let index = indexOf(flicButton) {
			buttons[index].connected = true
		}
	}
	
	func buttonIsReady(_ button: FLICButton) {
		print("buttonIsReady")
		reloadButtons()
	}
	
	func button(_ flicButton: FLICButton, didDisconnectWithError error: Error?) {
		print("didDisconnectWithError", error ?? "")
		if let index = indexOf(flicButton) {
			buttons[index].connected = false
		}
	}
	
	func button(_ button: FLICButton, didFailToConnectWithError error: Error?) {
		print("didFailToConnectWithError", error ?? "")
	}
	
	func managerDidRestoreState(_ manager: FLICManager) {
		print("managerDidRestoreState")
		reloadButtons()
	}
	
	func manager(_ manager: FLICManager, didUpdate state: FLICManagerState) {
		print("managerDidUpdate")
	}
	
	func button(_ flicButton: FLICButton, didReceiveButtonDown queued: Bool, age: Int) {
		print("didReceiveButtonDown")
		if let index = indexOf(flicButton) {
			buttons[index].pushed = true
		}
	}
	
	func button(_ flicButton: FLICButton, didReceiveButtonUp queued: Bool, age: Int) {
		print("didReceiveButtonUp")
		if let index = indexOf(flicButton) {
			buttons[index].pushed = false
		}
	}
	
	func indexOf(_ flicButton: FLICButton) -> Int?{
		for (i, button) in self.buttons.enumerated() {
			if button.identifier == flicButton.identifier {
				return i
			}
		}
		return nil
	}
	
	func getButton(uuid: UUID) -> Button? {
		for button in self.buttons {
			if button.identifier == uuid {
				return button
			}
		}
		return nil
	}
	
	func reloadButtons() {
		DispatchQueue.main.async {
			var buttons: [Button] = []
			if let manager = FLICManager.shared() {
				for flicButton in manager.buttons() {
					buttons.append(Button(flicButton))
				}
			}
			self.buttons = buttons
		}
	}
	
	func removeButton(_ button: ViewModel.Button) {
		if let flicButton = FLICManager.shared()?.buttons().first(where: { $0.identifier == button.identifier }) {
			Task {
				defer {
					reloadButtons()
				}
				
				do {
					try await FLICManager.shared()?.forgetButton(flicButton)
				}
			}
		}
	}
	
	func scan() {
		scanState = nil
		isScanning = true
		FLICManager.shared()?.scanForButtons(stateChangeHandler: { event in
			print(event);
			self.scanState = event
		}, completion: { button, error in
			self.isScanning = false
		})
	}
}

struct ContentView: View {
	
	@StateObject var viewModel = ViewModel()
	
	var body: some View {
		VStack {
			if (viewModel.buttons.count == 0) {
				List() {
					HStack {
						Spacer()
						Text("No Flics").foregroundColor(.gray)
						Spacer()
					}
				}
			} else {
				List(viewModel.buttons, id:\.identifier) { button in
					let color: Color = button.pushed ? .blue : button.connected ? .green : .yellow
					GeometryReader { geometry in
						HStack{
							Circle().frame(width: 10, height: geometry.size.height).foregroundColor(color)
							Text(button.name ?? "My Flic")
							Spacer()
							Image(systemName: "trash")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.foregroundColor(.red)
								.frame(width: 15)
						}
						.padding(0)
						.onTapGesture {
							viewModel.buttonToBeRemoved = button
							viewModel.promptToRemoveButton = true
						}
					}
				}
				.alert(isPresented: $viewModel.promptToRemoveButton) {
					Alert(title: Text("Remove"), message: Text("Do you want to remove this button?"), primaryButton: .destructive(Text("Remove")) {
						if let buttonToBeRemoved = viewModel.buttonToBeRemoved {
							viewModel.removeButton(buttonToBeRemoved)
						}
					}, secondaryButton: .default(Text("Cancel")))
				}
			}
			
			VStack {
				if viewModel.isScanning {
					HStack {
						Text([
							FLICButtonScannerStatusEvent.discovered: "Discovered",
							FLICButtonScannerStatusEvent.connected: "Connected",
							FLICButtonScannerStatusEvent.verified: "Verified",
							FLICButtonScannerStatusEvent.verificationFailed: "Verification failed",
						][viewModel.scanState] ?? "Looking for buttons")
						Spacer().frame(width: 5)
						ProgressView()
					}
				} else {
					Button(action: {
						print("start scan");
						viewModel.scan()
					}) {
						Text("Add Flic")
						Image(systemName: "plus.circle")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(.blue)
							.frame(width: 20)
					}
				}
			}.padding(20)
		}
		.padding(0)
	}
}

#Preview {
	ContentView(viewModel: ViewModel(preview: true))
}

#Preview {
	let viewModel = ViewModel(preview: true)
	viewModel.buttons = [
		ViewModel.Button(identifier: UUID(), name: "My First Flic"),
		ViewModel.Button(identifier: UUID(), name: "My Second Flic")
	]
	return ContentView(viewModel: viewModel)
}
