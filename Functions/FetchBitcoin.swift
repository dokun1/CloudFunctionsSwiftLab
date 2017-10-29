let bitcoinURL = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json")

func main(args: [String:Any]) -> [String:Any] {
    fetchCurrency(bitcoinURL!, completion: { fetchedCurrency, error in
        if error != nil {
            return ["error" : error!.localizedDescription]
        }
        guard let currency = fetchedCurrency else {
            return ["error" : "Sorry, something uncool happened!"]
        }
        return ["currency" : currency.json]
    })
} 

struct CurrencyResponse {
    var name: String
    var value: Float
    var currencyCode: String
    
    var json: [String: AnyObject] {
        return ["name" : name as AnyObject, "value" : value as AnyObject, "currencyCode" : currencyCode as AnyObject]
    }
}

enum APIError: Error {
    case noResponse
    case parsingError
    case unknown
}

typealias CurrencyResponseClosure = (_ currency: CurrencyResponse?, _ error: Error?) -> Void

func fetchCurrency(_ url: URL, completion: @escaping CurrencyResponseClosure) {
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            completion(nil, APIError.noResponse)
        }
        do {
            guard let data = data else {
                completion(nil, APIError.parsingError)
                return
            }
            guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject] else {
                completion(nil, APIError.parsingError)
                return
            }
            guard let bpi = json["bpi"] as? [String : AnyObject], let USD = bpi["USD"] as? [String : AnyObject] else {
                completion(nil, APIError.parsingError)
                return
            }
            let currency = CurrencyResponse(name: "Bitcoin",
                                            value: USD["rate_float"] as! Float,
                                            currencyCode: USD["code"] as! String)
            completion(currency, nil)
        } catch {
            completion(nil, APIError.unknown)
        }
    }
    task.resume()
}