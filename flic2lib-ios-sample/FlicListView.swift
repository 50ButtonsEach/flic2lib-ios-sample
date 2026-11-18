//
//  ContentView.swift
//  flic2lib-ios-sample
//
//  Created by Oskar Öberg on 2024-02-09.
//

import SwiftUI
import flic2lib

struct FlicListView: View {
    
    @StateObject var viewModel = FlicListViewModel()
    
    var body: some View {
		VStack {
			if viewModel.buttons.isEmpty {
				emptyStateView
			} else {
				buttonListView
			}
			
			scanSectionView
		}
    }
    
    private var emptyStateView: some View {
        List {
            HStack {
                Spacer()
                Text("No Flics connected")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    private var buttonListView: some View {
        List {
            ForEach(viewModel.buttons) { button in
                FlicButtonRow(button: button, onRemove: {
                    viewModel.buttonToBeRemoved = button
                    viewModel.promptToRemoveButton = true
                })
            }
        }
        .alert(isPresented: $viewModel.promptToRemoveButton) {
            Alert(
                title: Text("Remove Flic"),
                message: Text("Do you want to remove this button?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let button = viewModel.buttonToBeRemoved {
                        viewModel.removeButton(button)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var scanSectionView: some View {
        VStack {
            if viewModel.isScanning {
                HStack {
                    Text(scanStatusText(for: viewModel.scanState))
                    Spacer().frame(width: 10)
                    ProgressView()
                }
                .padding()
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
				.padding()
			}
        }
        .alert(item: Binding<AlertError?>(
            get: { viewModel.scanError.map { AlertError(message: $0) } },
            set: { _ in viewModel.scanError = nil }
        )) { alertError in
            Alert(title: Text("Error"), message: Text(alertError.message), dismissButton: .default(Text("OK")))
        }
    }
    
    struct AlertError: Identifiable {
        let id = UUID()
        let message: String
    }
    
    private func scanStatusText(for state: FLICButtonScannerStatusEvent?) -> String {
        switch state {
        case .discovered: return "Discovered..."
        case .connected: return "Connected..."
        case .verified: return "Verified!"
        case .verificationFailed: return "Verification failed"
        case nil: return "Looking for buttons..."
        @unknown default: return "Scanning..."
        }
    }
}

struct FlicButtonRow: View {
    @ObservedObject var button: FlicButtonModel
    var onRemove: () -> Void
    
	var body: some View {
        HStack {
			Image(systemName: "circle.fill")
				.foregroundColor(button.state == .connected ? .green : .yellow)
            
			Text(button.serialNumber)
			
			buttonIndicator(number: 0)
			if button.isDuo {
				buttonIndicator(number: 1)
			}
			
			Spacer()
            
            Button(action: onRemove) {
                 Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }

    private func buttonIndicator(number: UInt8) -> some View {
        ZStack {
            if button.isDuo {
                let isDown = button.downButtons.contains(number)
                Circle()
                    .fill(isDown ? Color.primary : Color.clear)
                    .overlay(Circle().strokeBorder(Color.primary, lineWidth: 1.5))
                    .frame(width: 20, height: 20)

                Capsule()
                    .fill(isDown ? Color(uiColor: .systemBackground) : Color.primary)
                    .frame(width: 1.5, height: 10)
                    .offset(y: -4.5)
                    .rotationEffect(.degrees((button.pushTwistAngles[number] ?? 0) - 45))
            } else {
                Circle()
                    .fill(button.downButtons.contains(number) ? Color.primary : Color.clear)
                    .overlay(Circle().strokeBorder(Color.primary, lineWidth: 1.5))
                    .frame(width: 20, height: 20)
            }
        }
        .frame(width: 26, height: 26)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(button.isDuo ? (number == 0 ? "Big button" : "Small button") : "Button")
        .accessibilityValue(button.downButtons.contains(number) ? "Pressed" : "Released")
    }

}

#Preview {
    FlicListView(viewModel: FlicListViewModel(isPreview: true))
}
