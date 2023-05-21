//
//  Button.swift
//  Wundermental
//
//  Created by Nicolas Walter on 21.05.23.
//

import UIKit

@IBDesignable
class Button: UIButton {
    
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
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? .WBlue : .WGrey
        }
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
