import SwiftUI

struct IDAColorfulIcon: View {
    let systemName: String
    var size: CGFloat = 16
    var color: Color = .primary

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
    }
}
