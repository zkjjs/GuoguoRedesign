import SwiftUI

enum RootDestination: String, CaseIterable, Identifiable {
    case home, collection, history, search, settings
    var id: String { rawValue }
}

final class AppState: ObservableObject {
    @Published var selectedRoot: RootDestination = .home
}

struct MediaItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let symbol: String
    let colors: [Color]
}

private let demoMedia: [MediaItem] = [
    .init(id: 1, title: "牧神记", subtitle: "更新至第 84 集", symbol: "sparkles.tv", colors: [.indigo, .orange]),
    .init(id: 2, title: "一人之下", subtitle: "第 6 季 · 第 24 集", symbol: "bolt.fill", colors: [.blue, .cyan]),
    .init(id: 3, title: "模范出租车", subtitle: "2021 · 剧情", symbol: "car.fill", colors: [.black, .orange]),
    .init(id: 4, title: "流氓读书会", subtitle: "2025 · 热播", symbol: "book.closed.fill", colors: [.yellow, .orange]),
    .init(id: 5, title: "清潭国际高中", subtitle: "2023 · 校园", symbol: "graduationcap.fill", colors: [.blue, .purple])
]

struct RootView: View {
    @StateObject private var state = AppState()
    @State private var selectedMedia: MediaItem?
    @State private var favorites = Set<Int>()
    @State private var history = Set<Int>()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                AmbientGlassBackground()

                Group {
                    switch state.selectedRoot {
                    case .home:
                        HomeScreen(onSearch: { state.selectedRoot = .search }, onOpen: { selectedMedia = $0 })
                    case .collection:
                        MediaListScreen(title: "资源库", empty: "还没有收藏", symbol: "heart", items: demoMedia.filter { favorites.contains($0.id) }, onOpen: { selectedMedia = $0 })
                    case .history:
                        MediaListScreen(title: "观看记录", empty: "还没有观看记录", symbol: "clock", items: demoMedia.filter { history.contains($0.id) }, onOpen: { selectedMedia = $0 })
                    case .search:
                        SearchScreen(text: $searchText, onOpen: { selectedMedia = $0 })
                    case .settings:
                        SettingsScreen()
                    }
                }
                .padding(.bottom, 94)

                GlassDock(selection: $state.selectedRoot)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedMedia) { item in
                DetailScreen(
                    item: item,
                    isFavorite: favorites.contains(item.id),
                    onFavorite: {
                        if favorites.contains(item.id) { favorites.remove(item.id) } else { favorites.insert(item.id) }
                    },
                    onPlay: { history.insert(item.id) }
                )
            }
        }
        .tint(.blue)
    }
}

private struct AmbientGlassBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle().fill(.blue.opacity(0.12)).frame(width: 260, height: 260).blur(radius: 30).offset(x: -proxy.size.width * 0.38, y: -proxy.size.height * 0.32)
                Circle().fill(.pink.opacity(0.10)).frame(width: 240, height: 240).blur(radius: 34).offset(x: proxy.size.width * 0.40, y: -proxy.size.height * 0.18)
            }
        }.allowsHitTesting(false)
    }
}

private struct HomeScreen: View {
    let onSearch: () -> Void
    let onOpen: (MediaItem) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("首页").font(.system(size: 36, weight: .bold, design: .rounded))
                    Text("发现值得看的内容").foregroundStyle(.secondary)
                }

                Button(action: onSearch) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                        Text("搜索影片、番剧、演员")
                        Spacer()
                        Image(systemName: "mic.fill").foregroundStyle(.blue)
                    }
                    .foregroundStyle(.secondary).padding(.horizontal, 17).frame(height: 54).glass(radius: 27)
                }.buttonStyle(.plain)

                Button { onOpen(demoMedia[0]) } label: {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: demoMedia[0].colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 248).clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        VStack(alignment: .leading, spacing: 8) {
                            Text("正在热播").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
                            Text(demoMedia[0].title).font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                            Label("继续播放", systemImage: "play.fill").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                .padding(.horizontal, 14).padding(.vertical, 9).background(.ultraThinMaterial, in: Capsule())
                        }.padding(20)
                    }
                }.buttonStyle(.plain)

                SectionHeader(title: "继续观看", count: "7")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(demoMedia.prefix(2)) { item in
                            Button { onOpen(item) } label: { ContinueCard(item: item) }.buttonStyle(.plain)
                        }
                    }
                }

                SectionHeader(title: "电视 · 韩国", count: "45")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(demoMedia.dropFirst(2)) { item in
                            Button { onOpen(item) } label: { PosterCard(item: item) }.buttonStyle(.plain)
                        }
                    }
                }
            }.padding(.horizontal, 20).padding(.top, 14)
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let count: String
    var body: some View { HStack { Text(title).font(.title3.bold()); Spacer(); Text("\(count) ›").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary) } }
}

private struct ContinueCard: View {
    let item: MediaItem
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PosterArtwork(item: item).frame(width: 210, height: 132)
            Text(item.title).font(.headline).foregroundStyle(.primary)
            Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
            ProgressView(value: min(Double(item.id) * 0.16, 0.85)).tint(.blue)
        }.frame(width: 210, alignment: .leading).padding(12).glass(radius: 26)
    }
}

private struct PosterCard: View {
    let item: MediaItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PosterArtwork(item: item).frame(width: 142, height: 198)
            Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).lineLimit(1)
            Text(item.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }.frame(width: 142, alignment: .leading)
    }
}

private struct PosterArtwork: View {
    let item: MediaItem
    var body: some View {
        ZStack {
            LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: item.symbol).font(.system(size: 38)).foregroundStyle(.white.opacity(0.9))
        }.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct MediaListScreen: View {
    let title: String
    let empty: String
    let symbol: String
    let items: [MediaItem]
    let onOpen: (MediaItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.system(size: 34, weight: .bold, design: .rounded))
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: symbol).font(.system(size: 42)).foregroundStyle(.secondary)
                        Text(empty).font(.headline)
                        Text("从影片详情页添加后会显示在这里").font(.subheadline).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity).padding(.vertical, 52).glass(radius: 30)
                } else {
                    ForEach(items) { item in
                        Button { onOpen(item) } label: {
                            HStack(spacing: 14) {
                                PosterArtwork(item: item).frame(width: 76, height: 90)
                                VStack(alignment: .leading, spacing: 5) { Text(item.title).font(.headline); Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary) }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }.padding(12).glass(radius: 24)
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(20)
        }
    }
}

private struct SearchScreen: View {
    @Binding var text: String
    let onOpen: (MediaItem) -> Void
    private var results: [MediaItem] { text.isEmpty ? demoMedia : demoMedia.filter { $0.title.localizedCaseInsensitiveContains(text) || $0.subtitle.localizedCaseInsensitiveContains(text) } }

    var body: some View {
        VStack(spacing: 14) {
            Text("搜索").font(.system(size: 34, weight: .bold, design: .rounded)).frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索影片、番剧、演员", text: $text).textInputAutocapitalization(.never).autocorrectionDisabled()
                if !text.isEmpty { Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) } }
            }.padding(.horizontal, 16).frame(height: 52).glass(radius: 26)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results) { item in
                        Button { onOpen(item) } label: {
                            HStack(spacing: 13) {
                                PosterArtwork(item: item).frame(width: 68, height: 78)
                                VStack(alignment: .leading, spacing: 4) { Text(item.title).font(.headline); Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary) }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }.padding(10).glass(radius: 22)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }.padding(.horizontal, 20).padding(.top, 14)
    }
}

private struct SettingsScreen: View {
    @AppStorage("autoplay") private var autoplay = true
    @AppStorage("preferHD") private var preferHD = true
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("设置").font(.system(size: 34, weight: .bold, design: .rounded))
                VStack(spacing: 0) {
                    Toggle("自动播放下一集", isOn: $autoplay).padding(16)
                    Divider().padding(.leading, 16)
                    Toggle("优先高清画质", isOn: $preferHD).padding(16)
                }.glass(radius: 26)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Guoguo Swift", systemImage: "swift").font(.headline)
                    Text("原生 SwiftUI · iOS 16.0+").font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(18).glass(radius: 26)
            }.padding(20)
        }
    }
}

private struct DetailScreen: View {
    let item: MediaItem
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onPlay: () -> Void
    @State private var showPlayerNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PosterArtwork(item: item).frame(height: 310)
                VStack(alignment: .leading, spacing: 7) { Text(item.title).font(.system(size: 30, weight: .bold)); Text(item.subtitle).foregroundStyle(.secondary) }
                HStack(spacing: 12) {
                    Button { onPlay(); showPlayerNotice = true } label: { Label("开始播放", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 14) }
                        .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
                    Button(action: onFavorite) { Image(systemName: isFavorite ? "heart.fill" : "heart").frame(width: 48, height: 48) }
                        .buttonStyle(.bordered).buttonBorderShape(.circle)
                }
                Text("简介").font(.title3.bold())
                Text("这里会接入旧客户端服务端协议返回的真实影片详情、剧集、播放源和播放器。当前原生版已经完成详情导航、收藏和观看记录闭环。")
                    .foregroundStyle(.secondary).lineSpacing(5)
            }.padding(20)
        }
        .navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
        .alert("播放器接口准备中", isPresented: $showPlayerNotice) { Button("好", role: .cancel) {} } message: { Text("点击已写入观看记录；后续接入真实播放地址和 AliyunPlayer。") }
    }
}

private struct GlassDock: View {
    @Binding var selection: RootDestination
    private let items: [(RootDestination, String, String)] = [
        (.home, "house.fill", "首页"), (.collection, "square.stack.fill", "资源库"), (.history, "clock.fill", "记录"), (.search, "magnifyingglass", "搜索"), (.settings, "gearshape.fill", "设置")
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.0) { item in
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) { selection = item.0 }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.1).font(.system(size: 18, weight: .semibold))
                        Text(item.2).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selection == item.0 ? Color.blue : Color.secondary)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background { if selection == item.0 { Capsule().fill(Color.white.opacity(0.46)).padding(4) } }
                }.buttonStyle(.plain)
            }
        }
        .padding(5).background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.62), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.10), radius: 22, y: 10)
    }
}

private extension View {
    func glass(radius: CGFloat) -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.65), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.055), radius: 20, y: 9)
    }
}
