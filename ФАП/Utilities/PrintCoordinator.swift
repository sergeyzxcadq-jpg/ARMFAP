import SwiftUI

struct PrintCoordinator {
    static func printView<Content: View>(_ view: Content) {
        #if os(macOS)
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        let printOperation = NSPrintOperation(view: NSHostingView(rootView: view), printInfo: printInfo)
        printOperation.run()
        #endif
    }
}
