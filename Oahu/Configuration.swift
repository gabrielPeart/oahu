import Foundation
import WebKit

class Configuration {
    let webkitUserContentController = WKUserContentController()
    let scriptHandler = ScriptHandler()
    let processPool = WKProcessPool()

    lazy var cookieInScript: WKUserScript = {
        let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies!
            .filter{!$0.name.containsString("'")}
            .map{"if (cookieNames.indexOf('\($0.name)') == -1) { document.cookie='\($0.javascriptString)'; };\n"}
            .joinWithSeparator("")

        let script = "var cookieNames = document.cookie.split('; ').map(function(cookie) { return cookie.split('=')[0] } );\n"
            .stringByAppendingString(cookies)

        return WKUserScript(source: script, injectionTime: .AtDocumentStart, forMainFrameOnly: false)
    }()

    lazy var cookieOutScript: WKUserScript = {
        return WKUserScript(source: "window.webkit.messageHandlers.updateCookies.postMessage(document.cookie);", injectionTime: .AtDocumentStart, forMainFrameOnly: false)
    }()

    var config: WKWebViewConfiguration {
        let webkitWebViewConfiguration = WKWebViewConfiguration()
        webkitUserContentController.addUserScript(cookieInScript)
        webkitUserContentController.addUserScript(cookieOutScript)
        webkitUserContentController.addScriptMessageHandler(scriptHandler, name: "updateCookies")

        webkitWebViewConfiguration.processPool = processPool
        webkitWebViewConfiguration.userContentController = webkitUserContentController

        return webkitWebViewConfiguration
    }
}
