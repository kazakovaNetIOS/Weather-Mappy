//
//  MarkerView.swift
//  Weather Mappy
//
//  Created by Natalia Kazakova on 04/08/2019.
//  Copyright © 2019 Natalia Kazakova. All rights reserved.
//

import UIKit

class MarkerView: UIView {
    
    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    private var pictureImageName: String = "dunno"
    private var temperatureValue: String = "-"
    
    convenience init(frame: CGRect, picture: String, temperature: String) {
        self.init(frame: frame)
        
        self.pictureImageName = picture
        self.temperatureValue = temperature
        
        setupViews()
    }
    
    private func setupViews() {
        let xibView = loadViewFromXib()
        
        xibView.frame = self.bounds
        xibView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        pictureImageView.image = UIImage(named: pictureImageName)
        temperatureLabel.text = "\(temperatureValue) °C"
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.6).cgColor
        
        self.addSubview(xibView)
    }
    
    private func loadViewFromXib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "MarkerView", bundle: bundle)
        
        return nib.instantiate(withOwner: self, options: nil).first! as! UIView
    }
}

extension MarkerView {
    func asImage() -> UIImage {        
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        return renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
