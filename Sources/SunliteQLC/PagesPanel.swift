import SwiftUI

/// Левая панель со списком страниц приборов (аналог "Pages" в Sunlite Suite 2):
/// _MASTER со значком звезды сверху, затем пользовательские страницы с
/// диапазоном DMX-каналов.
struct PagesPanel: View {
    @EnvironmentObject var document: LightingDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PAGES")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(SunliteTheme.textDark.opacity(0.7))
                .padding(.horizontal, 8)
                .padding(.top, 6)
                .padding(.bottom, 4)

            Divider()

            List(document.pages) { page in
                pageRow(page)
                    .listRowBackground(
                        document.selectedPageID == page.id
                            ? SunliteTheme.accentOrange.opacity(0.25)
                            : Color.clear
                    )
                    .onTapGesture {
                        document.selectedPageID = page.id
                    }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(SunliteTheme.panelLight)
    }

    private func pageRow(_ page: FixturePage) -> some View {
        HStack(spacing: 6) {
            Image(systemName: page.isMaster ? "star.fill" : "lightbulb.fill")
                .foregroundColor(page.isMaster ? SunliteTheme.accentOrange : SunliteTheme.panelDark)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(page.name)
                    .font(.system(size: 11, weight: page.isMaster ? .bold : .regular))
                    .foregroundColor(SunliteTheme.textDark)
                Text("\(page.channelRangeStart + 1) - \(page.channelRangeEnd + 1)")
                    .font(.system(size: 9))
                    .foregroundColor(SunliteTheme.textDark.opacity(0.6))
            }

            Spacer()

            Image(systemName: "lock.open")
                .font(.system(size: 9))
                .foregroundColor(SunliteTheme.textDark.opacity(0.4))
            Image(systemName: "eye.fill")
                .font(.system(size: 9))
                .foregroundColor(SunliteTheme.textDark.opacity(0.4))
        }
        .padding(.vertical, 2)
    }
}
