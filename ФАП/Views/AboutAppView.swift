import SwiftUI

struct AboutAppView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cross.case.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            Text("АРМ Фельдшерско-акушерского пункта")
                .font(.title2.bold())
            Text("Версия 2.0 (2026)")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
