//
//  ViewController.swift
//  flic2lib-example
//
//  Created by Oskar on 2019-12-09.
//  Copyright © 2020 Oskar Öberg. All rights reserved.
//

import UIKit
import flic2lib

class ViewController: UIViewController, UITableViewDataSource, FLICButtonDelegate, FLICManagerDelegate, FlicButtonTableViewCellDelegate {

	@IBOutlet var textView: UITextView!
	@IBOutlet var tableView: UITableView!
	@IBOutlet var scanButton: UIButton!
	
	private var _isScanning = false
	var isScanning: Bool {
		get {
			return _isScanning
		}
		set (isScanning) {
			_isScanning = isScanning
			self.scanButton.setTitle(isScanning ? "Stop Scan" : "Start Scan", for: .normal)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		FLICManager.configure(with: self, buttonDelegate: self, background: true)
		tableView.separatorStyle = .none
		tableView.allowsSelection = false
		tableView.rowHeight = 80.0
		scanButton.layer.cornerRadius = 4.0
	}
	
	@IBAction func startScan(sender: UIButton) {
		if (isScanning) {
			FLICManager.shared()?.stopScan()
			log("Scan stopped")
			self.isScanning = false
			return
		}
		
		log("Scan started")
		
		self.isScanning = true
		
		FLICManager.shared()?.scanForButtons(stateChangeHandler: { (event: FLICButtonScannerStatusEvent) in
			switch (event) {
				case .discovered:
					self.log("A Flic was discovered.")
					break;
				case .connected:
					self.log("A Flic is being verified.")
					break;
				case .verified:
					self.log("The Flic was verified successfully.")
					break;
				case .verificationFailed:
					self.log("The Flic verification failed.")
					break;
				default:
					break;
			}
		}) { (button: FLICButton?, error: Error?) in
			self.log("Scanner completed with error:", error.debugDescription)
			self.isScanning = false
			
			if (error == nil) {
				if let button = button {
					self.log("Successfully verified:", button.name, button.bluetoothAddress, button.serialNumber);
					button.triggerMode = .click // Listening to single click only improves latency
				}
			}
		}
	}
	
	@IBAction func removeAllButtons(sender: UIButton) {
		for button in FLICManager.shared()?.buttons() ?? [] {
			FLICManager.shared()?.forgetButton(button, completion: { (uuid: UUID, error: Error?) in
				self.log("Forgot button: ", button)
			})
		}
	}
	
	@IBAction func segmentControlValueChanged(sender: UISegmentedControl) {
		if (sender.selectedSegmentIndex == 0) {
			tableView.isHidden = false
			textView.isHidden = true
		} else {
			tableView.isHidden = true
			textView.isHidden = false
		}
	}
	
	func log(_ items: Any?...) {
		let string = NSMutableString()
		
		for item in items {
			string.append(item != nil ? String(describing: item!) + " " : "")
		}
		
		print(string)
		
		textView.text = "\(textView.text!)\n\(string)"
		textView.scrollRangeToVisible(NSMakeRange(textView.text.count - 1, 1))
	}
	
	func cellForButton(button: FLICButton) -> FlicButtonTableViewCell? {
		if let index = FLICManager.shared()?.buttons().firstIndex(of: button) {
			return self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? FlicButtonTableViewCell
		}
		return nil
	}
	
	// MARK: - FLICManagerDelegate
	
	func managerDidRestoreState(_ manager: FLICManager) {
		log("Did restore state with", manager.buttons().count, "buttons")
		self.tableView.reloadData()
	}
	
	func manager(_ manager: FLICManager, didUpdate state: FLICManagerState) {
		log("Did update state:", state.rawValue)
		if (state == .unsupported) {
			log("flic2lib is not supported on this version of iOS")
		}
		self.tableView.reloadData()
	}
	
	// MARK: - FLICButtonDelegate
	
	func buttonDidConnect(_ button: FLICButton) {
		log("Button did connect: ", button.name)
		self.tableView.reloadData()
	}
	
	func buttonIsReady(_ button: FLICButton) {
		log("Button is ready: ", button.name)
		self.tableView.reloadData()
	}
	
	func button(_ button: FLICButton, didDisconnectWithError error: Error?) {
		log("Button ", button.name, " did disconnect with error:", error)
		self.tableView.reloadData()
	}
	
	func button(_ button: FLICButton, didFailToConnectWithError error: Error?) {
		log("Did fail to connect with error:", error)
	}
	
	func button(_ button: FLICButton, didReceiveButtonClick queued: Bool, age: Int) {
		log(button.name, "was clicked!")
	}
	
	func button(_ button: FLICButton, didReceiveButtonDown queued: Bool, age: Int) {
		let cell = cellForButton(button: button)
		cell?.flicIconView.backgroundColor = .blue
	}
	
	func button(_ button: FLICButton, didReceiveButtonUp queued: Bool, age: Int) {
		let cell = cellForButton(button: button)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			cell?.flicIconView.backgroundColor = .green
		}
	}
	
	// MARK: - UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return FLICManager.shared()?.buttons().count ?? 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let button = FLICManager.shared()!.buttons()[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "FlicButtonTableViewCell", for: indexPath) as! FlicButtonTableViewCell
			cell.textLabel?.text = button.name
			cell.flicButton = button
			cell.delegate = self
			cell.connectToggleButton.titleLabel?.text = button.state == .connected ? "Disconnect" : "Connect"
			cell.flicIconView.backgroundColor = button.state == .connected ? .green : .gray
		
		return cell
	}
	
	// MARK: - FlicButtonTableViewCellDelegate
	
	func connectToggleButtonPressed(_ cell: FlicButtonTableViewCell, button: FLICButton) {
		if (button.state == .connected) {
			button.disconnect()
		} else {
			button.connect()
			let cell = cellForButton(button: button)
			cell?.flicIconView.backgroundColor = .orange
		}
	}
	
	func forgetButtonPressed(_ cell: FlicButtonTableViewCell, button: FLICButton) {
		FLICManager.shared()?.forgetButton(button, completion: { (uuid: UUID, error: Error?) in
			self.log("Forgot button: ", button)
			self.tableView.reloadData()
		})
	}
}
