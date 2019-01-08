//
//  NetworkManager.swift
//  foodie
//
//  Created by Austin Du on 2018-07-04.
//  Copyright © 2018 JAY. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AWSCore
import AWSS3

class NetworkManager {
    
    let kS3bucketName = "foodie-prod-menu-item-images"
    
    static let shared: NetworkManager = {
        let instance = NetworkManager()
        return instance
    }()
    
    enum Router: URLRequestConvertible {
        
        case updateMenuItem(restaurantId: Int, menuItemId: Int, imageUrl: String)
        case getRestaurant(restaurantId: Int)
        case getRestaurantMenu(restaurantId: Int)
        case searchRestaurant(query: String)
        case searchDish(query: String)
        case insertMenuItem(restaurantId: Int, params: [String: AnyObject])
        
        static let baseURLString = "https://foodie-server-prod.herokuapp.com/"
        
        var method: HTTPMethod {
            switch self {
            case .updateMenuItem:
                return .put
            case .getRestaurant:
                return .get
            case .getRestaurantMenu:
                return .get
            case .searchRestaurant:
                return .get
            case .searchDish:
                return .get
            case .insertMenuItem:
                return .post
            }
        }
        
        var path: String {
            switch self {
            case .updateMenuItem(let restaurantId, let menuItemId, _):
                return "restaurant/\(restaurantId)/item/\(menuItemId)"
            case .getRestaurant(let restaurantId):
                return "restaurant/\(restaurantId)"
            case .getRestaurantMenu(let restaurantId):
                return "restaurant/\(restaurantId)/menu"
            case .searchRestaurant(let query):
                return "search/restaurant/\(query)"
            case .searchDish(let query):
                return "search/item/\(query)"
            case .insertMenuItem(let restaurantId, _):
                return "restaurant/\(restaurantId)/item"
            }
        }
        
        var body: [String: Any] {
            switch self {
            case .updateMenuItem(_, _, let imageUrl):
                return RequestBodyFactory.shared.updateMenuItem(imageUrl: imageUrl)
            case .insertMenuItem(_, let params):
                return params
            default:
                return [:]
            }
        }
        
        func asURLRequest() throws -> URLRequest {
            let url = try Router.baseURLString.asURL()
            
            var urlRequest = URLRequest(url: url.appendingPathComponent(path))
            urlRequest.httpMethod = method.rawValue
            urlRequest.timeoutInterval = 60.0
            
            urlRequest = try URLEncoding.default.encode(urlRequest, with: body)
            
            return urlRequest
        }
    }
    
    func getStatusCode( response: DataResponse<Any> ) -> Int {
        if let innerResponse = response.response {
            return innerResponse.statusCode
        } else {
            return -1
        }
    }
    
    // MARK: Public Functions
    func insertMenuItem(restaurantId: Int,
                        itemName: String?,
                        itemImage: UIImage?,
                        description: String?,
                        sectionName: String?,
                        price: Float?,
                        completion: @escaping (JSON?, Error?, Int) -> Void ) {
        guard restaurantId >= 0, itemName != nil, itemImage != nil else { return }
        
        uploadImage(image: itemImage, restaurantId: restaurantId) { (url, error) in
            if let urlString = url?.absoluteString, error == nil {
                
                var json: JSON = JSON([:])
                
                json["item_name"].string = itemName!
                json["item_image"].string = urlString
                
                if let description = description {
                    json["description"].string = description
                }
                if let sectionName = sectionName {
                    json["section_name"].string = sectionName
                }
                if let price = price {
                    json["price"].float = price
                }
                
                Alamofire.request(Router.insertMenuItem(restaurantId: restaurantId,
                                                        params: json.dictionaryObject! as [String: AnyObject]))
                    .responseJSON { response in
                        let code = self.getStatusCode( response: response )
                        switch response.result {
                        case .success(let value):
                            completion(JSON(value), nil, code)
                        case .failure(let error):
                            completion(nil, error, code)
                        }
                }
            }
        }
        
    }
    
    func updateMenuItem( restaurantId: Int,
                         menuItemId: Int,
                         image: UIImage?,
                         completion: @escaping (JSON?, Error?, Int) -> Void ) {
        guard image != nil else { return }
        
        // upload to S3
        let imageUrl = "testurl"
        
        Alamofire.request(Router.updateMenuItem(restaurantId: restaurantId,
                                                menuItemId: menuItemId,
                                                imageUrl: imageUrl))
            .responseJSON { response in
                let code = self.getStatusCode( response: response )
                
                switch response.result {
                case .success(let value):
                    completion(JSON(value), nil, code)
                case .failure(let error):
                    completion(nil, error, code)
                }
        }
    }
    
    func getRestaurant( restaurantId: Int,
                        completion: @escaping (JSON?, Error?, Int) -> Void ) {
        Alamofire.request(Router.getRestaurant(restaurantId: restaurantId))
            .responseJSON { response in
                let code = self.getStatusCode( response: response )
                switch response.result {
                case .success(let value):
                    completion(JSON(value), nil, code)
                case .failure(let error):
                    completion(nil, error, code)
                }
        }
    }
    
    func getRestaurantMenu( restaurantId: Int,
                            completion: @escaping (JSON?, Error?, Int) -> Void ) {
        Alamofire.request(Router.getRestaurantMenu(restaurantId: restaurantId))
            .responseJSON { response in
                let code = self.getStatusCode( response: response )
                switch response.result {
                case .success(let value):
                    completion(JSON(value), nil, code)
                case .failure(let error):
                    completion(nil, error, code)
                }
        }
    }
    
    func searchRestaurant( query: String?,
                           completion: @escaping (JSON?, Error?, Int) -> Void ) {
        guard query != nil else { return }
        Alamofire.request(Router.searchRestaurant(query: query!))
            .responseJSON { response in
                let code = self.getStatusCode( response: response )
                switch response.result {
                case .success(let value):
                    completion(JSON(value), nil, code)
                case .failure(let error):
                    completion(nil, error, code)
                }
        }
    }
    
    func searchDish( query: String?,
                     completion: @escaping (JSON?, Error?, Int) -> Void ) {
        guard query != nil else { return }
        Alamofire.request(Router.searchDish(query: query!))
            .responseJSON { response in
                let code = self.getStatusCode( response: response )
                switch response.result {
                case .success(let value):
                    completion(JSON(value), nil, code)
                case .failure(let error):
                    completion(nil, error, code)
                }
        }
    }
    
    func uploadImage(image: UIImage?, restaurantId: Int,
                     completion: @escaping (URL?, Error?) -> Void) {
        
        guard image != nil else { return }
        
//        let image = image?.imageResized(newSize: CGSize(width: 100, height: 100))
        
        let data: Data = image!.jpegData(compressionQuality: 0 )!
        let key = "\(restaurantId)/\(UUID().uuidString).jpg"
        
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async(execute: {
                // Do something e.g. Update a progress bar.
            })
        }
        
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                print("Progress: \(task.progress)")
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    
                }
            })
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        
        transferUtility.uploadData(data,
                                   bucket: kS3bucketName,
                                   key: key,
                                   contentType: "image/jpeg",
                                   expression: expression,
                                   completionHandler: completionHandler).continueWith { (task) -> AnyObject? in
                                    if let error = task.error {
                                        print("Error: \(error.localizedDescription)")
                                    }
                                    
                                    let newImageUrl =  URL(string: "https://s3.us-east-2.amazonaws.com/foodie-prod-menu-item-images/\(key)")
                                    print("Successfully uploaded image to: \(newImageUrl?.absoluteString)")
                                    
                                    completion(newImageUrl, task.error)
                                    return nil
        }
    }
    
        func downloadData() {
            let expression = AWSS3TransferUtilityDownloadExpression()
            expression.progressBlock = {(task, progress) in DispatchQueue.main.async(execute: {
                // Do something e.g. Update a progress bar.
            })
            }
    
            var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
            completionHandler = { (task, URL, data, error) -> Void in
                DispatchQueue.main.async(execute: {
                    // Do something e.g. Alert a user for transfer completion.
                    // On failed downloads, `error` contains the error object.
                    print("Progress: \(task.progress)")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                        
                    }
                })
            }
    
            let transferUtility = AWSS3TransferUtility.default()
            transferUtility.downloadData(
                fromBucket: kS3bucketName,
                key: "a.png",
                expression: expression,
                completionHandler: completionHandler
                ).continueWith {
                    (task) -> AnyObject? in if let error = task.error {
                        print("Error: \(error.localizedDescription)")
                    }
    
                    if task.result != nil {
                        // Do something with downloadTask.
                    }
                    
                    return nil
            }
        }
    
}

extension UIImage {
    func imageResized( newSize: CGSize ) -> (UIImage) {
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        let imageRef = self.cgImage
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // Set the quality level to use when rescaling
        context!.interpolationQuality = CGInterpolationQuality.high
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
        
        context?.concatenate(flipVertical)
        
        // Draw into the context; this scales the image
        context?.draw(imageRef!, in: newRect)
        
        let newImageRef = (context?.makeImage()!)! as CGImage
        let newImage = UIImage(cgImage: newImageRef)
        
        // Get the resized image from the context and a UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
}