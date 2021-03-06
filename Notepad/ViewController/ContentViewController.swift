//
//  ContentViewController.swift
//  Notepad
//
//  Created by 김기현 on 2020/02/13.
//  Copyright © 2020 김기현. All rights reserved.
//

import UIKit
import CoreData

// 라이브러리 : https://github.com/onevcat/Kingfisher
import Kingfisher

class ContentViewController: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    
    var note: Note?
    private var imageArray: [String] = []
    private let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setUpContent()
        
        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        } else {
            self.navigationItem.leftBarButtonItem?.title = "메모"
        }
    }
    
    private func setUpContent() {
        titleLabel.text = note?.title
        contentLabel.text = note?.content
        imageArray = note?.images?.compactMap { ($0 as AnyObject).imageAddress } ?? []
        collectionView.reloadData()
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        
        let alert = UIAlertController(title: "삭제", message: "삭제하시겠습니까?", preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: "확인", style: .default) { (_) in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
            fetchRequest.predicate = NSPredicate(format: "title = %@", self.titleLabel.text ?? "")
            
            do {
                let test = try managedContext.fetch(fetchRequest)
                
                let objectToDelete = test[0] as! NSManagedObject
                
                for image in self.note!.images! {
                    if self.fileManager.fileExists(atPath: (image as AnyObject).imageAddress ?? "") {
                        try! self.fileManager.removeItem(atPath: (image as AnyObject).imageAddress ?? "")
                    }
                }
                
                managedContext.delete(objectToDelete)
                
                do {
                    try managedContext.save()
                } catch {
                    print(error)
                }
            } catch {
                print(error)
            }
            self.navigationController?.popViewController(animated: true)
        }
        
        let cancelButton = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(okButton)
        alert.addAction(cancelButton)
        
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editNote" {
            let vc = segue.destination as? ViewController
            vc?.note = note
            vc?.imageArray = self.imageArray
            
            self.navigationController?.popViewController(animated: true)
        } else if segue.identifier == "imageContent" {
            let vc = segue.destination as? ImageContentViewController
            vc?.imageArray = imageArray
        }
    }
}

extension ContentViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contentCollectionCell", for: indexPath) as! ContentImageCollectionViewCell
        
        if imageArray[indexPath.row].contains("http") {
            let url = URL(string: imageArray[indexPath.row])
            cell.imageView.kf.setImage(with: url)
        } else {
            cell.imageView.image = UIImage.init(contentsOfFile: imageArray[indexPath.row])
        }
        return cell
    }
}

extension ContentViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
