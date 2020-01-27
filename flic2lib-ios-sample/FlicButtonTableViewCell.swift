//
//  FlicButtonTableViewCell.swift
//  flic2lib-example
//
//  Created by Oskar on 2019-12-16.
//  Copyright © 2019 Oskar Öberg. All rights reserved.
//

import UIKit
import flic2lib

protocol FlicButtonTableViewCellDelegate {
	func connectToggleButtonPressed(_ cell: FlicButtonTableViewCell, button: FLICButton)
	func forgetButtonPressed(_ cell: FlicButtonTableViewCell, button: FLICButton)
}

class FlicButtonTableViewCell: UITableViewCell {

	@IBOutlet var flicTextLabel: UILabel!
	@IBOutlet var flicIconView: UIView!
	@IBOutlet var connectToggleButton: UIButton!
	var flicButton: FLICButton?
	var delegate: FlicButtonTableViewCellDelegate?
	
    override func awakeFromNib() {
        super.awakeFromNib()
		self.flicIconView?.layer.cornerRadius = self.flicIconView.frame.size.width/2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
	
	override var textLabel: UILabel? {
		return self.flicTextLabel
	}
	
	@IBAction func connectToggleButtonPressed(sender: Any) {
		delegate?.connectToggleButtonPressed(self, button: self.flicButton!)
	}
	
	@IBAction func forgetButtonPressed(sender: Any) {
		delegate?.forgetButtonPressed(self, button: self.flicButton!)
	}

}
