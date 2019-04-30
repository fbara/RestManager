//
//  ViewController.swift
//  RestManager
//
//  Created by Frank Bara.
//  Copyright © 2019 BaraLabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let rest = RestManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUsersList()
    }
    
    func getUsersList() {
        guard let url = URL(string: "https://reqres.in/api/users") else { return }
        
        rest.makeRequest(toURL: url, withHTTPMethod: .get) { (results) in
            if let data = results.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                guard let userData = try? decoder.decode(UserData.self, from: data) else { return }
                print(userData.description)
            }
        }
    }
}
