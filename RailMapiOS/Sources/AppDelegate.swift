//
//  AppDelegate.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/03/2025.
//

import UIKit
import OHHTTPStubs
import OHHTTPStubsSwift

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        if ProcessInfo.processInfo.arguments.contains("STUB_NETWORK") {
            HTTPStubs.setEnabled(true)
            stubneworkRequests()
        }
        
        return true
    }
    
    private func stubneworkRequests() {
        HTTPStubs.removeAllStubs()
        
        stub(condition: isMethodGET() && pathStartsWith("stop")) { _ in
            guard let path = OHPathForFile("GET_stop_9706_SNCF_TGV.json", type(of: self)) else {
                LogManager.error("Fichier stub introuvable")
                return HTTPStubsResponse(error: NSError(domain: "TEST", code: 500))
            }
            
            return HTTPStubsResponse(
                fileAtPath: path,
                statusCode: 200,
                headers: [
                    "Content-Type": "application/json",
                    "content-length": "208887",
                    "connection": "keep-alive",
                    "date": "Fri, 28 Mar 2025 14:41:18 GMT"
                ]
            )
        }
    }
}
