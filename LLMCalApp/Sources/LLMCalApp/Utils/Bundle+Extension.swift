import Foundation

extension Bundle {
    static var appBundle: Bundle = {
        let mainBundle = Bundle.main
        let bundlePath = mainBundle.bundlePath
        let resourcePath = bundlePath + "/Contents/Resources"
        
        if let bundle = Bundle(path: resourcePath) {
            return bundle
        }
        return mainBundle
    }()
}
