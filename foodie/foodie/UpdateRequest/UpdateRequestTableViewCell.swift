//
//  UpdateRequestTableViewCell.swift
//  foodie
//
//  Created by Austin Du on 2019-03-06.
//  Copyright © 2019 JAY. All rights reserved.
//

import UIKit

class UpdateRequestTableViewCell: UITableViewCell {

    let reasonLabel = UILabel()
    let selectedMarker = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildComponents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        buildComponents()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buildComponents()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectedMarker.image = selected ? UIImage(named: "icn_checked") : UIImage(named: "icn_unchecked")
    }
    
    func configureCell(reason: String) {
        reasonLabel.text = reason
    }
    
    func buildComponents() {
        selectionStyle = .none
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        contentView.applyAutoLayoutInsetsForAllMargins(to: stackView, with: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))

        selectedMarker.image = UIImage(named: "icn_unchecked")
        selectedMarker.contentMode = .scaleAspectFit
        selectedMarker.translatesAutoresizingMaskIntoConstraints = false
        selectedMarker.widthAnchor.constraint(equalToConstant: 25).isActive = true
        selectedMarker.heightAnchor.constraint(equalToConstant: 25).isActive = true
        stackView.addArrangedSubview(selectedMarker)
        
        reasonLabel.font = UIFont(font: .helveticaNeue, size: 16)
        reasonLabel.numberOfLines = 0
        reasonLabel.textColor = UIColor.cc45DarkGrey
        
        stackView.addArrangedSubview(reasonLabel)
        
    }

}
