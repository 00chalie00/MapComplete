//
//  PopUpVC.swift
//  ReMap
//
//  Created by formathead on 14/06/2019.
//  Copyright © 2019 formathead. All rights reserved.
//

import UIKit

class PopUpVC: UIViewController {

    //Outlet
    @IBOutlet weak var popUpImage: UIImageView!
    
    var passImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popUpImage.image = passImage
        
        addDoubleTap()
    }
    
    func initSetUp(image: UIImage) {
        self.passImage = image
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubletapDismiss(gesture:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }
    
    @objc func doubletapDismiss(gesture: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
}//End Of The Class

