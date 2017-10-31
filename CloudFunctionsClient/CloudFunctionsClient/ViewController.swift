//
//  ViewController.swift
//  CloudFunctionsClient
//
//  Created by David Okun IBM on 10/29/17.
//  Copyright © 2017 David Okun. All rights reserved.
//

import UIKit

enum ChangeResponse {
    case increase
    case decrease
    case noChange
    case newCode
}

public struct CurrencyKeys {
    static let lastCurrencyCode = "com.ibm.cloudFunctions.swiftSummit.currencyCode"
    static let lastCurrencyValue = "com.ibm.cloudFunctions.swiftSummit.currencyValue"
}

class ViewController: UIViewController {

    @IBOutlet weak var currencyTextField: UITextField!
    @IBOutlet weak var currencyValue: UILabel!
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var requestButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencyTextField.delegate = self
        comparisonLabel.alpha = 0.0
        currencyValue.alpha = 0.0
    }
    
    @IBAction func requestButtonTapped() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        requestButton.isEnabled = false
        WebAPI.fetchPrice(for: currencyTextField.text!) { response, errorMessage in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.requestButton.isEnabled = true
            if let error = errorMessage {
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            } else if response != nil  {
                self.handle(response)
            }
        }
    }
    
    func handle(_ response: CurrencyResponse?) {
        guard let currency = response else {
            let alert = UIAlertController(title: "Error", message: "Could not find currency", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.currencyValue.text = "\(currency.value)"
        switch trackPriceChange(currency) {
        case .increase:
            self.currencyValue.textColor = UIColor.green
            self.comparisonLabel.text = "The value went up!"
            break
        case .decrease:
            self.currencyValue.textColor = UIColor.red
            self.comparisonLabel.text = "The value went down!"
            break
        case .newCode:
            self.currencyValue.textColor = UIColor.blue
            self.comparisonLabel.text = "This is a new currency."
            break
        case .noChange:
            self.currencyValue.textColor = UIColor.blue
            self.comparisonLabel.text = "The value hasn't changed."
        }
        
        self.currencyValue.alpha = 1.0
        self.comparisonLabel.alpha = 1.0
    }
    
    func trackPriceChange(_ currency: CurrencyResponse) -> ChangeResponse {
        defer {
            saveValues(for: currency)
        }
        guard let oldCode = UserDefaults.standard.string(forKey: CurrencyKeys.lastCurrencyCode) else {
            return .newCode
        }
        if oldCode != currency.code {
            return .newCode
        }
        guard let oldValue = UserDefaults.standard.string(forKey: CurrencyKeys.lastCurrencyValue) else {
            return .newCode
        }
        if Double(oldValue)! > Double(currency.value) {
            return .decrease
        } else if Double(oldValue)! == Double(currency.value) {
            return .noChange
        } else {
            return .increase
        }
    }
    
    func saveValues(for currency: CurrencyResponse) {
        UserDefaults.standard.set(currency.code, forKey: CurrencyKeys.lastCurrencyCode)
        UserDefaults.standard.set("\(currency.value)", forKey: CurrencyKeys.lastCurrencyValue)
        UserDefaults.standard.synchronize()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        requestButtonTapped()
        return true
    }
}

