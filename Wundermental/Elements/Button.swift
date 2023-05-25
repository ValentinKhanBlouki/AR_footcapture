//
//  Button.swift
//  Wundermental
//
//  Created by Nicolas Walter on 21.05.23.
//

import UIKit

@IBDesignable
class Button: UIButton {
    
    private let padding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = .WBlue
        layer.cornerRadius = 8
        clipsToBounds = true
        setTitleColor(.white, for: [])
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)

    }
    
    func setSecondary() {
        backgroundColor = .WGrey
    }
    
    func setPrimary() {
        backgroundColor = .WBlue
    }
    
    var toggledOn: Bool = true {
        didSet {
            if !isEnabled {
                backgroundColor = .WGrey
                return
            }
            backgroundColor = toggledOn ? .WBlue : .WLightBlue
        }
    }
}
