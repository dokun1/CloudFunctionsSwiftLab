func main(args: [String:Any]) -> [String:Any] {
    guard let name = args["name"] as? String else {
        return ["output" : "Welcome to Serverless Swift!"]
    }
    return ["output" : "Welcome to Serverless Swift, \(name)!"]
} 
