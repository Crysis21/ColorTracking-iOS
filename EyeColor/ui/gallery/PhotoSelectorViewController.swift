//
//  PhotoSelectorViewController.swift
//  EyeColor
//
//  Created by Cristian Holdunu on 15/12/2017.
//  Copyright © 2017 Hold1. All rights reserved.
//

import UIKit
import SwaggerClient
import NVActivityIndicatorView
import SDWebImage
import Nuke

class PhotoSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    
    public var photos: [WhiteImage]?
    public var drawColor: UIColor?
    public var graphImage: UIImage?
    public var detectedColors: [DetectedColor]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource=self
        tableView.delegate=self
        loadPhotos()
        loadingView.startAnimating()
    }
    
    private func loadPhotos() {
        SwaggerClientAPI.WhitephotoAPI.getPhotosUsingGET { (images, error) in
            guard error == nil else {
                print("failed to load images \(error.debugDescription)")
                return
            }
            self.photos = images
            self.tableView.reloadData()
            self.loadingView.stopAnimating()
        }
    }
    
    //MARK: TableView data
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let whitePhoto = photos![indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "whitePhotoCell", for: indexPath) as! WhitePhotoTableViewCell
        cell.whitePhoto = whitePhoto
        Manager.shared.loadImage(with: URL(string: whitePhoto.thumbUrl!)!, into: cell.photoView)
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ResultViewController, let cell = sender as? WhitePhotoTableViewCell {
            vc.whitePhoto = cell.whitePhoto
            vc.selectedColor = self.drawColor
            vc.graphImage = self.graphImage
            vc.detectedColors = self.detectedColors
        }
    }

}
