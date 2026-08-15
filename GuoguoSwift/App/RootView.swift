import SwiftUI

struct MediaItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let symbol: String
    let colors: [Color]
}

private let sampleMedia: [MediaItem] = [
    .init(id: 1, title: "牧神记", subtitle: "更新至第 84 集", symbol: "sparkles.tv", colors: [.indigo, .orange]),
    .init(id: 2, title: "一人之下", subtitle: "第 6 季 · 第 24 集", symbol: "bolt.fill", colors: [.blue, .cyan]),
    .init(id: 3, title: "模范出租车", subtitle: "2021 · 剧情", symbol: "car.fill", colors: [.black, .orange]),
    .init(id: 4, title: "流氓读书会", subtitle: "2025 · 热播", symbol: "book.closed.fill", colors: [.yellow, .orange]),
    .init(id: 5, title: "清潭国际高中", subtitle: "2023 · 校园", symbol: "graduationcap.fill", colors: [.blue, .purple])
]

struct RootView: View {
    @StateObject private var appState = AppState()
    @State private var selectedMedia: MediaItem?
    @State private var favorites = Set<Int>()
    @State private var watched = Set<Int>()
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                ambientBackground

                Group {
                    switch appState.selectedRoot {
                    case .home:
                        HomeView(onSearch: { appState.selectedRoot = .search }, onOpen: { selectedMedia = $0 })
                    case .collection:
                        CollectionView(items: sampleMedia.filter { favorites.contains($0.id) }, onOpen: { selectedMedia = $0 })
                    case .history:
                        HistoryView(items: sampleMedia.filter { watched.contains($0.id) }, onOpen: { selectedMedia = $0 })
                    case .search:
                        SearchView(query: $query, onOpen: { selectedMedia = $0 })
                    case .settings:
                        SettingsView()
                    }
                }
                .padding(.bottom, 96)

                FloatingGlassDock(selected: $appState.selectedRoot)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedMedia) { item in
                DetailView(
                    item: item,
                    isFavorite: favorites.contains(item.id),
                    onToggleFavorite: {
                        if favorites.contains(item.id) { favorites.remove(item.id) } else { favorites.insert(item.id) }
                    },
                    onPlay: { watched.insert(item.id) }
                )
            }
        }
        .tint(.blue)
    }

    private var ambientBackground: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 28)
                    .offset(x: -proxy.size.width * 0.35, y: -proxy.size.height * 0.30)
                Circle()
                    .fill(Color.pink.opacity(0.10))
                    .frame(width: 240, height: 240)
                    .blur(radius: 34)
                    .offset(x: proxy.size.width * 0.42, y: -proxy.size.height * 0.18)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct HomeView: View {
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
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 17)
                    .frame(height: 54)
                    .glassSurface(radius: 27)
                }
                .buttonStyle(.plain)

                Button { onOpen(sampleMedia[0]) } label: {
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(colors: sampleMedia[0].colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 248)
                            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        VStack(alignment: .leading, spacing: 8) {
                            Text("正在热播").font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.8))
                            Text(sampleMedia[0].title).font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                            HStack {
                                Label("继续播放", systemImage: "play.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 9)
                                    .background(.ultraThinMaterial, in: Capsule())
                                Spacer()
                                Text("1 / 5").font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(20)
                    }
                }
                .buttonStyle(.plain)

                sectionTitle("继续观看", count: "7")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(sampleMedia.prefix(2)) { item in
                            Button { onOpen(item) } label: { ContinueCard(item: item) }
                                .buttonStyle(.plain)
                        }
                    }
                }

                sectionTitle("电视 · 韩国", count: "45")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sampleMedia.dropFirst(2)) { item in
                            Button { onOpen(item) } label: { PosterCard(item: item) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
        }
    }

    private func sectionTitle(_ title: String, count: String) -> some View {
        HStack {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            Text("\(count) ›").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
        }
    }
}

private struct ContinueCard: View {
    let item: MediaItem
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: item.symbol).font(.system(size: 40)).foregroundStyle(.white.opacity(0.88))
            }
            .frame(width: 210, height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            Text(item.title).font(.headline).foregroundStyle(.primary)
            Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
            ProgressView(value: Double(item.id) * 0.13).tint(.blue)
        }
        .frame(width: 210, alignment: .leading)
        .padding(12)
        .glassSurface(radius: 26)
    }
}

private struct PosterCard: View {
    let item: MediaItem
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: item.symbol).font(.system(size: 38)).foregroundStyle(.white.opacity(0.9))
            }
            .frame(width: 142, height: 198)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text(item.title).font(.subheadline.weight(.semibold)).lineLimit(1).foregroundStyle(.primary)
            Text(item.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(width: 142, alignment: .leading)
    }
}

private struct CollectionView: View {
    let items: [MediaItem]
    let onOpen: (MediaItem) -> Void
    var body: some View { LibraryLikeView(title: "资源库", emptyTitle: "还没有收藏", emptySymbol: "heart", items: items, onOpen: onOpen) }
}

private struct HistoryView: View {
    let items: [MediaItem]
    let onOpen: (MediaItem) -> Void
    var body: some View { LibraryLikeView(title: "观看记录", emptyTitle: "还没有观看记录", emptySymbol: "clock", items: items, onOpen: onOpen) }
}

private struct LibraryLikeView: View {
    let title: String
    let emptyTitle: String
    let emptySymbol: String
    let items: [MediaItem]
    let onOpen: (MediaItem) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(title).font(.system(size: 34, weight: .bold, design: .rounded))
                if items.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: emptySymbol).font(.system(size: 42)).foregroundStyle(.secondary)
                        Text(emptyTitle).font(.headline)
                        Text("从影片详情页添加后会显示在这里").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 52).glassSurface(radius: 30)
                } else {
                    ForEach(items) { item in
                        Button { onOpen(item) } label: {
                            HStack(spacing: 14) {
                                ZStack { LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: item.symbol).foregroundStyle(.white) }
                                    .frame(width: 78, height: 92).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                VStack(alignment: .leading, spacing: 5) { Text(item.title).font(.headline); Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary) }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }.padding(12).glassSurface(radius: 24)
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(20)
        }
    }
}

private struct SearchView: View {
    @Binding var query: String
    let onOpen: (MediaItem) -> Void
    private var results: [MediaItem] { query.isEmpty ? sampleMedia : sampleMedia.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query) } }
    var body: some View {
        VStack(spacing: 14) {
            Text("搜索").font(.system(size: 34, weight: .bold, design: .rounded)).frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("搜索影片、番剧、演员", text: $query).textInputAutocapitalization(.never).autocorrectionDisabled()
                if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) } }
            }.padding(.horizontal, 16).frame(height: 52).glassSurface(radius: 26)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(results) { item in
                        Button { onOpen(item) } label: {
                            HStack(spacing: 13) {
                                ZStack { LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing); Image(systemName: item.symbol).foregroundStyle(.white) }
                                    .frame(width: 68, height: 78).clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                                VStack(alignment: .leading, spacing: 4) { Text(item.title).font(.headline); Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary) }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }.padding(10).glassSurface(radius: 22)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }.padding(.horizontal, 20).padding(.top, 14)
    }
}

private struct SettingsView: View {
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
                }.glassSurface(radius: 26)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Guoguo Swift", systemImage: "swift").font(.headline)
                    Text("原生 SwiftUI · iOS 16.0+").font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(18).glassSurface(radius: 26)
            }.padding(20)
        }
    }
}

private struct DetailView: View {
    let item: MediaItem
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onPlay: () -> Void
    @State private var showPlayerNotice = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ZStack {
                    LinearGradient(colors: item.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: item.symbol).font(.system(size: 72)).foregroundStyle(.white.opacity(0.9))
                }
                .frame(height: 310).clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Text(item.title).font(.system(size: 30, weight: .bold))
                    Text(item.subtitle).foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button {
                        onPlay(); showPlayerNotice = true
                    } label: {
                        Label("开始播放", systemImage: "play.fill").frame(maxWidth: .infinity).padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)

                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart").frame(width: 48, height: 48)
                    }
                    .buttonStyle(.bordered).buttonBorderShape(.circle)
                }

                Text("简介").font(.title3.bold())
                Text("这里将承载从旧客户端接口迁移过来的真实影片详情、剧集列表、播放源以及播放器入口。当前页面已经完成原生导航和收藏/记录状态闭环。")
                    .foregroundStyle(.secondary).lineSpacing(5)
            }.padding(20)
        }
        .navigationTitle(item.title).navigationBarTitleDisplayMode(.inline)
        .alert("播放器接口准备中", isPresented: $showPlayerNotice) { Button("好", role: .cancel) {} } message: { Text("这次点击已经写入观看记录；下一阶段接入真实播放地址和 AliyunPlayer。") }
    }
}

private struct FloatingGlassDock: View {
    @Binding var selected: RootDestination
    private let items: [(RootDestination, String, String)] = [
        (.home, "house.fill", "首页"), (.collection, "square.stack.fill", "资源库"), (.history, "clock.fill", "记录"), (.search, "magnifyingglass", "搜索"), (.settings, "gearshape.fill", "设置")
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.0) { item in
                Button { withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) { selected = item.0 } } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.1).font(.system(size: 18, weight: .semibold))
                        Text(item.2).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selected == item.0 ? Color.blue : Color.secondary)
                    .frame(maxWidth: .infinity).frame(height: 58)
                    .background {
                        if selected == item.0 { Capsule().fill(Color.white.opacity(0.46)).padding(4).matchedGeometrySafe() }
                    }
                }.buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.62), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.10), radius: 22, y: 10)
    }
}

private extension View {
    func glassSurface(radius: CGFloat) -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Color.white.opacity(0.65), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.055), radius: 20, y: 9)
    }

    @ViewBuilder func matchedGeometrySafe() -> some View { self }
}
