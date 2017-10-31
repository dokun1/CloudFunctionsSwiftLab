//
//  WebAPI.swift
//  CloudFunctionsClient
//
//  Created by David Okun IBM on 10/29/17.
//  Copyright © 2017 David Okun IBM. All rights reserved.
//

import UIKit

private struct WebAPIParams {
    static var hostURL: URL? {
        guard let urlString = UserDefaults.standard.string(forKey: WebAPIConstantKeys.hostURL) else {
            return nil
        }
        return URL(string: urlString)
    }
    
    static var openWhiskToken: String? {
        return UserDefaults.standard.string(forKey: WebAPIConstantKeys.openWhiskToken)
    }
}

public struct WebAPIConstantKeys {
    static let hostURL = "com.ibm.cloud.LogisticsWizardMobile.hostURLKey"
    static let openWhiskToken = "com.ibm.cloud.LogisticsWizardMobile.openWhiskToken"
    static let defaultLongitude = "com.ibm.cloud.LogisticsWizardMobile.defaultLongitude"
    static let defaultLatitude = "com.ibm.cloud.LogisticsWizardMobile.defaultLatitude"
    static let shouldUseDefaultLocation = "com.ibm.cloud.LogisticsWizardMobile.shouldUseDefaultLocation"
}

public struct CurrencyResponse {
    var name: String
    var value: Double
    var currencyCode: String
}


private enum WebAPIError: Error {
    case noHostSpecified
    case noTokenSpecified
    case badParameters
    case other(reason: String)
}

class WebAPI: NSObject {
    class func fetchPrice(for currencyCode: String, _ completion: @escaping (_ response: CurrencyResponse?, _ errorMessage: String?) -> Void) {
        do {
            guard let authToken = WebAPIParams.openWhiskToken else {
                throw WebAPIError.noTokenSpecified
            }
            let headers = ["Content-Type" : "application/json", "Authorization" : "Basic " + authToken]
            let parameters = ["code" : currencyCode]
            let postData =  try JSONSerialization.data(withJSONObject: parameters, options: [])
            guard let url = WebAPIParams.hostURL else {
                throw WebAPIError.noHostSpecified
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = headers
            request.httpBody = postData as Data
            URLSession.shared.dataTask(with: request, completionHandler: { data, urlResponse, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(nil, error.localizedDescription)
                    } else {
                        do {
                            guard let data = data else {
                                completion(nil, "")
                                return
                            }
                            guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : AnyObject] else {
                                completion(nil, "Could not parse response")
                                return
                            }
                            guard let currencyResponse = json["currency"] as? [String : Any] else {
                                completion(nil, "Could not parse response")
                                return
                            }
                            guard let responseCode = currencyResponse["currencyCode"] as? String, let name = currencyResponse["name"] as? String, let value = currencyResponse["value"] as? Double else {
                                completion(nil, "Could not parse response")
                                return
                            }
                            let response = CurrencyResponse(name: name, value: value, currencyCode: responseCode)
                            completion(response, nil)
                        } catch {
                            completion(nil, "Uncaught exception")
                        }
                    }
                }
            }).resume()
        } catch WebAPIError.noHostSpecified {
            completion(nil, "No host URL specified")
        } catch WebAPIError.noTokenSpecified {
            completion(nil, "No OpenWhisk token specified")
        } catch WebAPIError.other(let errorReason) {
            completion(nil, errorReason)
        } catch {
            completion(nil, "Uncaught exception")
        }
    }
}

