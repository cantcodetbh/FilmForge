import SwiftUI

struct PresetStripView: View {
    @Binding var selectedProfile: FilmLookProfile

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ProfileCatalog.presets) { profile in
                    Button {
                        selectedProfile = profile
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(swatch(for: profile))
                                .frame(width: 132, height: 58)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: icon(for: profile))
                                        .font(.caption)
                                        .padding(7)
                                        .background(.thinMaterial, in: Circle())
                                        .padding(6)
                                }
                            Text(profile.name)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                        }
                        .padding(8)
                        .frame(width: 150, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedProfile.id == profile.id ? Color.accentColor.opacity(0.14) : Color(nsColor: .windowBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedProfile.id == profile.id ? Color.accentColor : Color(nsColor: .separatorColor), lineWidth: selectedProfile.id == profile.id ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func swatch(for profile: FilmLookProfile) -> LinearGradient {
        switch profile.id {
        case "kodak-funsaver-800", "kodak-funsaver-overexposed":
            LinearGradient(colors: [.yellow.opacity(0.76), .orange.opacity(0.76), .black.opacity(0.74)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "kodak-funsaver-wedding":
            LinearGradient(colors: [.orange.opacity(0.60), .pink.opacity(0.42), .black.opacity(0.60)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "kodak-funsaver-lowlight":
            LinearGradient(colors: [.black.opacity(0.92), .green.opacity(0.36), .orange.opacity(0.58)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "kodak-sun-haze":
            LinearGradient(colors: [.yellow.opacity(0.54), .white.opacity(0.78), .orange.opacity(0.36)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "fuji-quicksnap-400", "fuji-quicksnap-green":
            LinearGradient(colors: [.cyan.opacity(0.66), .green.opacity(0.46), .white.opacity(0.76)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "fuji-coastal-blue":
            LinearGradient(colors: [.blue.opacity(0.64), .cyan.opacity(0.58), .green.opacity(0.42)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "fuji-selfie-print":
            LinearGradient(colors: [.white.opacity(0.78), .mint.opacity(0.48), .pink.opacity(0.36)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "huji-direct", "huji-board-dark", "huji-light-leak":
            LinearGradient(colors: [.black.opacity(0.86), .orange.opacity(0.88), .red.opacity(0.70)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "huji-red-leak":
            LinearGradient(colors: [.red.opacity(0.88), .orange.opacity(0.82), .black.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "huji-alley-green":
            LinearGradient(colors: [.black.opacity(0.92), .green.opacity(0.44), .orange.opacity(0.52)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "huji-date-night":
            LinearGradient(colors: [.black.opacity(0.86), .red.opacity(0.62), .orange.opacity(0.64)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "dazz-d-exp", "dazz-night-market":
            LinearGradient(colors: [.black.opacity(0.90), .red.opacity(0.64), .blue.opacity(0.52)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "dazz-dfuns-market":
            LinearGradient(colors: [.black.opacity(0.88), .orange.opacity(0.72), .red.opacity(0.58)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "dazz-parallax-dark":
            LinearGradient(colors: [.black.opacity(0.94), .blue.opacity(0.46), .red.opacity(0.34)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "dazz-cpm35":
            LinearGradient(colors: [.mint.opacity(0.42), .pink.opacity(0.38), .white.opacity(0.78)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "dazz-soft-portrait":
            LinearGradient(colors: [.white.opacity(0.78), .pink.opacity(0.42), .mint.opacity(0.36)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "dazz-organic", "dazz-classic-room":
            LinearGradient(colors: [.brown.opacity(0.52), .pink.opacity(0.40), .white.opacity(0.70)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "imperfect-lab-print":
            LinearGradient(colors: [.gray.opacity(0.68), .yellow.opacity(0.36), .brown.opacity(0.45)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "kodak-funsaver-800-p1":
            LinearGradient(colors: [.yellow.opacity(0.84), .orange.opacity(0.82), .black.opacity(0.80)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "huji-direct-p1":
            LinearGradient(colors: [.black.opacity(0.92), .orange.opacity(0.94), .red.opacity(0.82)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "dazz-night-market-p1":
            LinearGradient(colors: [.black.opacity(0.94), .red.opacity(0.72), .blue.opacity(0.60)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "xpro-kodak-c41":
            LinearGradient(colors: [.teal.opacity(0.64), .yellow.opacity(0.72), .black.opacity(0.60)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "xpro-fuji-c41":
            LinearGradient(colors: [.cyan.opacity(0.66), .mint.opacity(0.48), .orange.opacity(0.52)], startPoint: .bottomLeading, endPoint: .topTrailing)
        case "xpro-huji-c41":
            LinearGradient(colors: [.teal.opacity(0.70), .yellow.opacity(0.78), .red.opacity(0.62)], startPoint: .bottomLeading, endPoint: .topTrailing)
        default:
            LinearGradient(colors: [.brown.opacity(0.55), .yellow.opacity(0.42), .gray.opacity(0.55)], startPoint: .bottomLeading, endPoint: .topTrailing)
        }
    }

    private func icon(for profile: FilmLookProfile) -> String {
        switch profile.id {
        case let id where id.hasSuffix("-p1"):
            "arrow.up.forward"
        case let id where id.hasPrefix("xpro-"):
            "arrow.triangle.swap"
        case let id where id.hasPrefix("kodak-") || id.hasPrefix("fuji-"):
            "camera.fill"
        case let id where id.hasPrefix("huji-"):
            "calendar.badge.clock"
        case let id where id.hasPrefix("dazz-"):
            "sparkles"
        case "imperfect-lab-print":
            "photo"
        default: "circle.lefthalf.filled"
        }
    }
}
