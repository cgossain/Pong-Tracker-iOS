//
//  TextFieldTableViewCell.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-30.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let detailTextField = UITextField()
    var textFieldChangedHandler: ((text: String) -> Void)?
    var textFieldReturnKeyHandler: (() -> Void)?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.commonInit()
    }
    
    func commonInit() {
        self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        // title label
        self.contentView.addSubview(titleLabel)
        self.titleLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
        self.titleLabel.textAlignment = NSTextAlignment.Left
        
        // detail text field
        self.contentView.addSubview(detailTextField)
        self.detailTextField.textAlignment = NSTextAlignment.Right;
        self.detailTextField.delegate = self
        
        // observe text field notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textFieldDidChangeNotification:", name: UITextFieldTextDidChangeNotification, object: self.detailTextField)
        
        // constraints
        self.setupConstraints()
        
//        titleLabel.layer.borderWidth = 1.0
//        titleLabel.layer.borderColor = UIColor.greenColor().CGColor
//        
//        detailTextField.layer.borderWidth = 1.0
//        detailTextField.layer.borderColor = UIColor.greenColor().CGColor
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "textFieldDidChangeNotification:", object: self.detailTextField)
    }
    
    // MARK: Overrides
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.textFieldChangedHandler = nil
    }
    
    // MARK: Text Field Notifications
    
    func textFieldDidChangeNotification(notification: NSNotification) {
        self.textFieldChangedHandler?(text: self.detailTextField.text!)
    }
    
    // MARK: Constraints
    
    func setupConstraints() {
        // label constraints
        self.titleLabel.mas_makeConstraints { make in
            make.centerY.equalTo()(self.contentView)
            make.leading.equalTo()(self.contentView).with().offset()(15);
        }
        
        // text field constraints
        self.detailTextField.mas_makeConstraints { make in
            make.centerY.equalTo()(self.contentView)
            make.leading.equalTo()(self.titleLabel.mas_trailing).with().offset()(8);
            make.trailing.equalTo()(self.contentView);
        }
    }
}

extension TextFieldTableViewCell: UITextFieldDelegate {
    
    // MARK - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // call the handler
        self.textFieldReturnKeyHandler?()
        return true
    }
    
}
