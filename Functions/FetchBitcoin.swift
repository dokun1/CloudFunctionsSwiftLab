import Foundation

let bitcoinURL = URL(string: "https://api.coindesk.com/v1/bpi/currentprice.json") 

struct CurrencyResponse {
    var name: String
    var value: Double
    var currencyCode: String
    
    var json: [String: Any] {
        return ["name" : name as! Any,
                "value" : value as! Any,
                "currencyCode" : currencyCode as! Any]
    }
}

enum APIError: Error {
    case noResponse
    case parsingError
    case unknown
}

func fetchCurrency(_ url: URL) throws -> CurrencyResponse {
    do {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Any else {
            throw APIError.parsingError
        }
        guard let types = json as? [String: Any] else {
            throw APIError.parsingError
        }
        guard let bpi = types["bpi"] as? [String : Any], let USD = bpi["USD"] as? [String : Any] else {
            throw APIError.parsingError
        }
        let currency = CurrencyResponse(name: "Bitcoin", value: USD["rate_float"] as! Double, currencyCode: USD["code"] as! String)
        return currency
    } catch {
        throw APIError.noResponse
    }
}

func main(args: [String:Any]) -> [String:Any] {
    do {
        let currency = try fetchCurrency(bitcoinURL!)
        return ["currency" : currency.json]
    } catch {
        return ["error" : "Something uncool happened"]
    }
}