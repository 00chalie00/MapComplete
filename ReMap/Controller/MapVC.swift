//
//  ViewController.swift
//  ReMap
//
//  Created by formathead on 13/06/2019.
//  Copyright © 2019 formathead. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    
    //Outlet
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var slideViewHeight: NSLayoutConstraint!
    @IBOutlet weak var slideView: UIView!
    
    //variable
    var locationManager = CLLocationManager()
    let locationAuth = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 100
    
    var spinner: UIActivityIndicatorView?
    var screenSize = UIScreen.main.bounds
    var progressLbl: UILabel?
    
    var collectionView: UICollectionView?
    var collectionviewLayout = UICollectionViewFlowLayout()
    
    var imageUrlArray = [String]()
    var imageDnArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        
        mapServiceConfigue()
        doubleTap()
        createCollectionView()
        
        registerForPreviewing(with: self, sourceView: collectionView!)
    }
    
    @IBAction func pressedMyPosition(_ sender: Any) {
        centerPosition()
    }
    
    func doubleTap() {
        let uiGeTap = UITapGestureRecognizer(target: self, action: #selector(doubleTappedMap(sender:)))
        uiGeTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(uiGeTap)
    }
    
    func slideViewUp() {
        slideViewHeight.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func slideViewDown() {
        cancelAllSessions()
        slideViewHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(slideViewDown))
        swipe.direction = .down
        slideView.addGestureRecognizer(swipe)
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.color = UIColor.white
        spinner?.style = .whiteLarge
        spinner?.startAnimating()
        spinner?.center = CGPoint(x: screenSize.width / 2.0, y: 150)
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func createCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionviewLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = UIColor.darkGray
        //collectionView?.isPagingEnabled = true
        //collectionView?.isScrollEnabled = true
        
        //Cell Size
        collectionviewLayout.itemSize = CGSize(width: 80.0, height: 80.0)
        
        //collectionviewLayout.minimumLineSpacing = 0
        //collectionviewLayout.minimumInteritemSpacing = 0
        collectionviewLayout.scrollDirection = .vertical
        
        slideView.addSubview(collectionView!)
    }
    
    func flickrURL(forApiKey key: String, withAnnotation annotation: Annotation, andNumberofPhotos number: Int) -> String {
        return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    }
    
    func getUrl(forAnnotation annotation: Annotation, completion: @escaping completionHandler) {
        Alamofire.request(flickrURL(forApiKey: API_KEY, withAnnotation: annotation, andNumberofPhotos: 50)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String,AnyObject> else {return}
            let photoDict = json["photos"] as! Dictionary<String,AnyObject>
            let photoDicArray = photoDict["photo"] as! [Dictionary<String,AnyObject>]
            for photo in photoDicArray {
                let postUrl = "https://live.staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_z_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            completion(true)
        }
    }
    
    func getImage(completion: @escaping completionHandler) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let dnimage = response.result.value else {return}
                self.imageDnArray.append(dnimage)
                if self.imageDnArray.count == self.imageUrlArray.count {
                    completion(true)
                }
            }
        }
    }
    
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: screenSize.width / 2.0, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 14)
        progressLbl?.textColor = UIColor.darkGray
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
        
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
        }
    }
    
}//End Of The Class

//===============================================MKMapViewDelegate===================================================================
extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "User Set The Pin")
        pinAnnotation.pinTintColor = UIColor.orange
        pinAnnotation.animatesDrop = true
        
        return pinAnnotation
    }
    
    func centerPosition() {
        guard let coordinate = locationManager.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func doubleTappedMap(sender: UITapGestureRecognizer) {
        removePinAnnotation()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        
        imageUrlArray = []
        imageDnArray = []
        
        collectionView?.reloadData()
        
        slideViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        let userTappedPosition = sender.location(in: mapView)
        let convert = mapView.convert(userTappedPosition, toCoordinateFrom: mapView)
        let region = MKCoordinateRegion(center: convert, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(region, animated: true)
        
        let annotation = Annotation(coordinate: convert, identifier: "User Select The Position")
        mapView.addAnnotation(annotation)
        
        getUrl(forAnnotation: annotation) { (success) in
            if success {
                print(self.imageUrlArray)
                print(self.imageUrlArray.count)
                self.getImage(completion: { (success) in
                    if success {
                        print("Download Complete")
                        self.removeSpinner()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePinAnnotation() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
}

//===========================================CLLocationManagerDelegate===============================================================
extension MapVC: CLLocationManagerDelegate {
    func mapServiceConfigue() {
        if locationAuth == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
}

//===========================================UICollectionViewDelegate================================================================
extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageDnArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else {return UICollectionViewCell()}
        let imageFromindex = imageDnArray[indexPath.row]
        let imageView = UIImageView(image:imageFromindex)
        
        //set the size of imageview in cell
        imageView.frame.size = CGSize(width: 80, height: 80)
        imageView.contentMode = .scaleAspectFit
        
        //set border(경계선)
        cell.layer.borderColor = UIColor.yellow.cgColor
        cell.layer.borderWidth = 2
        cell.layer.cornerRadius = 8
        
        cell.addSubview(imageView)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") as? PopUpVC else {return}
        popVC.initSetUp(image: imageDnArray[indexPath.row])
        
        present(popVC, animated: true, completion: nil)
    }
}

//===========================================UIViewControllerPreviewingDelegate===========================================================
extension MapVC: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //set the pressed position of collectionview by cgpoint and set the pressed cell of collectionview by cell
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else {return nil}
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") as? PopUpVC else {return nil}
        popVC.initSetUp(image: imageDnArray[indexPath.row])
        
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
