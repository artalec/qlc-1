import SwiftUI

struct ChannelFaderView: View {
    @EnvironmentObject var client: QLCPlusClient
    let channel: Int

    private var value: Binding<Double> {
        Binding(
            get: { Double(client.channelValues[channel] ?? 0) },
            set: { newValue in
                let clamped = UInt8(max(0, min(255, newValue.rounded())))
                client.setChannel(channel, value: clamped)
            }
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("CH \(channel + 1)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SunliteTheme.textDark)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.system(size: 10))
                    .foregroundColor(SunliteTheme.textDark.opacity(0.7))
            }
            Slider(value: value, in: 0...255)
                .tint(SunliteTheme.accentOrange)
        }
        .padding(8)
        .background(SunliteTheme.panelLight)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(SunliteTheme.panelDark, lineWidth: 0.5)
        )
    }
}
