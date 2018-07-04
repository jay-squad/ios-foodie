//
//  RestaurantDetailTableViewCell.swift
//  foodie
//
//  Created by Austin Du on 2018-05-31.
//  Copyright © 2018 JAY. All rights reserved.
//

import UIKit
import MapKit

class RestaurantDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var externalContainerView: UIView!
    @IBOutlet weak var mapContainerView: UIView!
    @IBOutlet weak var informationStackView: UIStackView!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantCuisineLabel: UILabel!
    @IBOutlet weak var restaurantPriceLabel: UILabel!
    @IBOutlet weak var restaurantDescriptionLabel: UILabel!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var restaurantWebsiteButton: UIButton!
    @IBOutlet weak var restaurantCallButton: UIButton!
    @IBOutlet weak var restaurantMedalsStackView: UIStackView!

    private var restaurant: Restaurant?
    
    var mapView = MKMapView()

    override func awakeFromNib() {
        super.awakeFromNib()

        externalContainerView.layer.shadowColor = UIColor(red: 200/255.0,
                                                               green: 200/255.0,
                                                               blue: 200/255.0,
                                                               alpha: 1.0).cgColor
        externalContainerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        externalContainerView.layer.shadowRadius = 8
        externalContainerView.layer.shadowOpacity = 0.25

        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(restaurant: Restaurant) {
        self.restaurant = restaurant

        restaurantNameLabel.text = restaurant.name
        restaurantCuisineLabel.text = restaurant.cuisine.joined(separator: ", ")
        restaurantPriceLabel.text = "$\(restaurant.priceRange[0]) - $\(restaurant.priceRange[1])"
        restaurantDescriptionLabel.text = restaurant.description
        
        if restaurantMedalsStackView.arrangedSubviews.count == 0 {
            for medal in restaurant.medals {
                let medalView = RestaurantDetailMedalView(medal: medal)
                restaurantMedalsStackView.addArrangedSubview(medalView)
            }
        }
        
        let annotation = MKPointAnnotation()
        let centerCoordinate = restaurant.location
        annotation.coordinate = centerCoordinate
        mapView.addAnnotation(annotation)
        
        mapView.setRegion(MKCoordinateRegion(center: restaurant.location,
                                             span: MKCoordinateSpan(latitudeDelta: 0.0275, longitudeDelta: 0.0275)),
                          animated: false)

        mapView.setCenter(restaurant.location, animated: false)
        
        buildComponents()
    }
    
    private func buildComponents() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.mapType = .standard
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        
        mapContainerView.addSubview(mapView)
        
        mapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor).isActive = true
    }

}
