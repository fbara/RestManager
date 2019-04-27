//
//  RestManager.swift
//  RestManager
//
//  Created by Frank Bara.
//  Copyright © 2019 BaraLabs. All rights reserved.
//

import Foundation

class RestManager {
    
    var requestHttpHeaders = RestEntity()
    var urlQueryParameters = RestEntity()
    var httpBodyParameters = RestEntity()
    var httpBody: Data?
    
    // MARK: - Private functions
    
    /* Append any URL query parameters specified through the urlQueryParameters property to the original URL.
    If there are not any parameters, this function will just return the original URL.
    */
    private func addURLQueryParameters(toURL url: URL) -> URL {
       //make sure that there are URL query parameters to append to the query. If not, we just return the input URL.
        if urlQueryParameters.totalItems() > 0 {
            //create a URLComponents object that will let us deal with the URL and its parts easily
            guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var queryItems = [URLQueryItem]()
            for (key, value) in urlQueryParameters.allValues() {
                let item = URLQueryItem(name: key, value: value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed))
                queryItems.append(item)
            }
            
            urlComponents.queryItems = queryItems
            
            guard let updatedURL = urlComponents.url else { return url }
            return updatedURL
        }
        return url
    }
    
    private func getHTTPBody() -> Data? {
        //check if the “Content-Type” request HTTP header has been set through the requestHttpHeaders property.
        guard let contentType = requestHttpHeaders.value(forKey: "Content-Type") else { return nil }
        
        if contentType.contains("application/json") {
            //values specified in the httpBodyParameters object must be converted into a JSON object (Data object) which in turn will be returned
            return try? JSONSerialization.data(withJSONObject: httpBodyParameters.allValues(), options: [.prettyPrinted, .sortedKeys])
        } else if contentType.contains("application/x-www-form-urlencoded") {
            //build a query string that would look like: "firstname=John&age=40"
            let bodyString = httpBodyParameters.allValues().map {"\($0)=\(String(describing: $1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))" }.joined(separator: "&")
            return bodyString.data(using: .utf8)
        } else {
            return httpBody
        }
    }
    
}

// MARK: - RestManager Extension
extension RestManager {
    
    enum HttpMethod: String {
        case get
        case post
        case put
        case patch
        case delete
    }
    
    enum CustomError: Error {
        case failedToCreateRequest
    }
    
    struct RestEntity {
        private var values: [String: String] = [:]
        
        mutating func add(value: String, forKey key: String) {
            values[key] = value
        }
        
        func value(forKey key: String) -> String? {
            return values[key]
        }
        
        func allValues() -> [String: String] {
            return values
        }
        
        func totalItems() -> Int {
            return values.count
        }
    }
    
    //Response object is returned from our class when making web requests
    struct Response {
        //will keep the actual response value
        var response: URLResponse?
        //the outcome of the request
        var httpStatusCode: Int = 0
        //
        var headers = RestEntity()
        
        init(fromURLResponse response: URLResponse? ) {
            guard let response = response else {return}
            self.response = response
            //if we can't tell what the status code is, return 0
            httpStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if let headerFields = (response as? HTTPURLResponse)?.allHeaderFields {
                for (key, value) in headerFields {
                    headers.add(value: "\(value)", forKey: "\(key)")
                }
            }
        }
    }
    
    struct Results {
        var data: Data?
        var response: Response?
        var error: Error?
        
        init(withData data: Data?, response: Response?, error: Error?) {
            self.data = data
            self.response = response
            self.error = error
        }
        
        init(withError error: Error) {
            self.error = error
        }
    }
}

extension RestManager.CustomError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .failedToCreateRequest: return NSLocalizedString("Unable to create the URL Request object.", comment: "")
        }
    }
}
