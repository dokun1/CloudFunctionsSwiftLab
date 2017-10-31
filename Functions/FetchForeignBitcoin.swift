import Foundation

let bitcoinURLPrefix = "https://api.coindesk.com/v1/bpi/currentprice/"

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
    case noCode
    case parsingError
    case unknown
}

func fetchCurrency(with countryCode: String) throws -> CurrencyResponse {
    do {
        let urlString = bitcoinURLPrefix + countryCode + ".json"
        guard let url = URL(string: urlString) else {
            throw APIError.unknown
        }
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Any else {
            throw APIError.parsingError
        }
        guard let types = json as? [String: Any] else {
            throw APIError.parsingError
        }
        guard let bpi = types["bpi"] as? [String : Any], let code = bpi[countryCode] as? [String : Any] else {
            throw APIError.noCode
        }
        let currency = CurrencyResponse(name: "Bitcoin", value: code["rate_float"] as! Double, currencyCode: countryCode)
        return currency
    } catch {
        throw APIError.noResponse
    }
}

func main(args: [String:Any]) -> [String:Any] {
    guard let countryCode = args["code"] as? String else {
        return ["error" : "No country code included"]
    }
    do {
        let currency = try fetchCurrency(with: countryCode)
        return ["currency" : currency.json]
    } catch {
        return ["error" : "Something uncool happened"]
    }
}