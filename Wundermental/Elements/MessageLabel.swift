//
//  Label.swift
//  Wundermental
//
//  Created by Nicolas Walter on 25.05.23.
//

import UIKit

class Message {
    // The title and body of this message
    private(set) var text: NSMutableAttributedString
    
    init(_ body: String, title: String? = nil) {
        if let title = title {
            // Make the title bold
            text = NSMutableAttributedString(string: "\(title)\n\(body)")
            let titleRange = NSRange(location: 0, length: title.count)
            text.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 17), range: titleRange)
        } else {
            text = NSMutableAttributedString(string: body)
        }
    }
    
    func printToConsole() {
        print(text.string)
    }
}

class MessageLabel: UILabel {
    
    private var hideTimer: Timer?
        
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += 20
        contentSize.height += 20
        return contentSize
    }
    
    private let padding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    override func drawText(in rect: CGRect) {
           super.drawText(in: rect.inset(by: padding))
       }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAppearance()
    }
    
    private func setupAppearance() {
        self.backgroundColor = UIColor.lightGray
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
    }
    
    func display(_ message: Message) {
        DispatchQueue.main.async {
            self.attributedText = message.text
            self.isHidden = false
        }
    }
    
    func setErrorMessage() {
        self.backgroundColor = UIColor.WLightRed
    }
    
    func showAutoHideMessage(_ message: Message) {
        hideTimer?.invalidate() // Cancel any previous hide timer
        
        DispatchQueue.main.async {
            self.attributedText = message.text
            self.isHidden = false
        }
        
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.hideMessage()
        }
    }
    
    func hideMessage() {
        DispatchQueue.main.async {
            self.text = ""
            self.isHidden = true
        }
        hideTimer?.invalidate()
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.text = ""
            self.isHidden = true
        }
    }
}
