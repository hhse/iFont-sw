import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var converter = FontConverter()
    @State private var selectedFiles: [URL] = []
    @State private var fileNames: [String] = []
    @State private var showingFilePicker = false
    @State private var showingSettings = false
    @State private var selectedMode: WeightMode = .single
    @State private var selectedCompat: CompatLayer = .ios18
    @State private var selectedFormat: OutputFormat = .ttc
    @State private var outputTemplate: String = ""
    @State private var showingLog = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isLongPressing = false
    @State private var pressProgress: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool
    @State private var globalApply = true
    @State private var selectedFileIndex = 0
    @State private var previewText = "这是一个我爱的小字体预览:(Abc123)"
    @State private var fontSize: Double = 20
    @State private var fontWeight: Double = 400
    @State private var fontLineHeight: Double = 1.2
    @State private var loadedFontData: [Data] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    uploadSection
                    modeSection
                    settingsSection
                    convertButton

                    if converter.isConverting {
                        progressSection
                    }

                    if showingLog && !converter.logs.isEmpty {
                        logSection
                    }

                    if !converter.results.isEmpty {
                        resultsSection
                    }

                    bottomAttribution

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("iFont")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.font, .ttfFont, .otfFont, .ttcFont],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .onAppear {
            loadSavedTemplate()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("纯本地 iOS 18~26 字体转换引擎\n支持 TTF / OTF / TTC 批量转换")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Upload Section
    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("加载源字体")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            Button(action: { showingFilePicker = true }) {
                VStack(spacing: 6) {
                    if fileNames.isEmpty {
                        Text("选取你的自定义字体")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("支持多选")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("\(fileNames.count) 个文件已加载")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        Text(fileNames.prefix(2).joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        if fileNames.count > 2 {
                            Text("...")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(white: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(fileNames.isEmpty ? Color.gray.opacity(0.5) : Color.gray, style: StrokeStyle(lineWidth: 1, dash: fileNames.isEmpty ? [5] : []))
                )
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            if !fileNames.isEmpty {
                FontPreviewList(
                    fileNames: Array(fileNames.prefix(3)),
                    loadedFontData: loadedFontData,
                    previewText: previewText,
                    fontSize: CGFloat(fontSize),
                    fontWeight: fontWeightValue,
                    lineHeight: CGFloat(fontLineHeight),
                    totalCount: fileNames.count
                )
                .padding(.top, 4)
            }
        }
    }

    private var fontWeightValue: Font.Weight {
        switch Int(fontWeight) {
        case 100: return .ultraLight
        case 200: return .thin
        case 300: return .light
        case 400: return .regular
        case 500: return .medium
        case 600: return .semibold
        case 700: return .bold
        case 800: return .heavy
        case 900: return .black
        default: return .regular
        }
    }

    // MARK: - Mode Section
    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择映射配置")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .textCase(.uppercase)

            HStack(spacing: 12) {
                ForEach(WeightMode.allCases) { mode in
                    modeButton(mode)
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func modeButton(_ mode: WeightMode) -> some View {
        Button(action: { selectedMode = mode }) {
            VStack(spacing: 4) {
                Text(mode.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Text(mode.description)
                    .font(.system(size: 10))
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedMode == mode ? Color.white.opacity(0.1) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedMode == mode ? Color.white : Color.gray.opacity(0.5), lineWidth: 1)
            )
            .foregroundColor(selectedMode == mode ? .white : .gray)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showingSettings.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .rotationEffect(.degrees(showingSettings ? 90 : 0))
                        .frame(width: 10)

                    Text("更多设置")
                        .font(.system(size: 13, weight: .medium))

                    Spacer()
                }
                .foregroundColor(showingSettings ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(showingSettings ? Color.white.opacity(0.08) : Color.clear)
                )
            }
            .buttonStyle(.plain)

            if showingSettings {
                VStack(spacing: 16) {
                    if fileNames.count > 1 {
                        Toggle(isOn: $globalApply) {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.system(size: 12))
                                Text("全局应用")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.gray)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                        .onChange(of: globalApply) { _ in
                            if !globalApply {
                                selectedFileIndex = 0
                            }
                        }

                        if !globalApply {
                            HStack(spacing: 12) {
                                Text("字体选择")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .frame(width: 70, alignment: .leading)

                                Picker("字体", selection: $selectedFileIndex) {
                                    ForEach(0..<fileNames.count, id: \.self) { index in
                                        Text("\(index + 1). \(fileNames[index])")
                                            .tag(index)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .clipped()
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Text("预览文本")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        TextField("预览文本", text: $previewText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(8)
                            .background(Color(white: 0.04))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .onChange(of: previewText) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "iFont_previewText")
                            }
                    }

                    HStack(spacing: 12) {
                        Text("字体大小")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        CustomSlider(value: $fontSize, in: 8...72, step: 1, thumbSize: 20)

                        Text("\(Int(fontSize))pt")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(width: 40)
                    }
                    .onChange(of: fontSize) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "iFont_fontSize")
                    }

                    HStack(spacing: 12) {
                        Text("字体粗细")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        CustomSlider(value: $fontWeight, in: 100...900, step: 100, thumbSize: 20)

                        Text("\(Int(fontWeight))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(width: 40)
                    }
                    .onChange(of: fontWeight) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "iFont_fontWeight")
                    }

                    HStack(spacing: 12) {
                        Text("字体行距")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        CustomSlider(value: $fontLineHeight, in: 0.8...2.5, step: 0.1, thumbSize: 20)

                        Text(String(format: "%.1f", fontLineHeight))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .frame(width: 40)
                    }
                    .onChange(of: fontLineHeight) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "iFont_fontLineHeight")
                    }

                    Divider()
                        .background(Color.gray.opacity(0.3))

                    HStack(spacing: 12) {
                        Text("输出名称")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        TextField("${fontName}UI", text: $outputTemplate)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                            .padding(8)
                            .background(Color(white: 0.04))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .focused($isTextFieldFocused)
                            .onChange(of: outputTemplate) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "iFont_outputTpl")
                            }
                    }

                    HStack(spacing: 12) {
                        Text("兼容配置")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        HStack(spacing: 8) {
                            ForEach(CompatLayer.allCases) { compat in
                                compatButton(compat)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Text("输出格式")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(width: 70, alignment: .leading)

                        HStack(spacing: 8) {
                            ForEach(OutputFormat.allCases) { format in
                                formatButton(format)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSettings)
                .opacity(showingSettings ? 1 : 0)
                .offset(y: showingSettings ? 0 : -8)
            }
        }
    }

    private func compatButton(_ compat: CompatLayer) -> some View {
        Button(action: { selectedCompat = compat }) {
            Text(compat.rawValue)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedCompat == compat ? Color.white.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedCompat == compat ? Color.white : Color.gray.opacity(0.5), lineWidth: 1)
                )
                .foregroundColor(selectedCompat == compat ? .white : .gray)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func formatButton(_ format: OutputFormat) -> some View {
        Button(action: { selectedFormat = format }) {
            Text(format.rawValue)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedFormat == format ? Color.white.opacity(0.1) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedFormat == format ? Color.white : Color.gray.opacity(0.5), lineWidth: 1)
                )
                .foregroundColor(selectedFormat == format ? .white : .gray)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Convert Button
    private var convertButton: some View {
        Button(action: startConversion) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: fileNames.isEmpty
                                ? [.clear]
                                : [.white.opacity(0.15), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 2)

                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.05))

                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: fileNames.isEmpty
                                ? [.gray.opacity(0.4)]
                                : [.white.opacity(0.9), .white.opacity(0.5), .white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: fileNames.isEmpty ? 1 : 1.5
                    )

                Text(converter.isConverting ? "PROCESSING..." : "START")
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(fileNames.isEmpty ? .gray : .white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .disabled(fileNames.isEmpty || converter.isConverting)
        .buttonStyle(.plain)
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .frame(height: 2)

                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * converter.progress, height: 2)
                        .animation(.easeInOut, value: converter.progress)
                }
            }
            .frame(height: 2)
        }
    }

    // MARK: - Log Section
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { showingLog.toggle() } }) {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .rotationEffect(.degrees(showingLog ? 90 : 0))
                    Text("日志")
                }
                .font(.system(size: 13))
                .foregroundColor(.gray)
            }

            if showingLog {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("日志")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: {
                            let logText = converter.logs.map { "[\($0.timeString)] \($0.text)" }.joined(separator: "\n")
                            UIPasteboard.general.string = logText
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(converter.logs) { log in
                                logLine(log)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(12)
                .background(Color(white: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .cornerRadius(8)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func logLine(_ log: LogEntry) -> some View {
        Text("[\(log.timeString)] \(log.text)")
            .foregroundColor(logColor(for: log.level))
    }

    private func logColor(for level: LogEntry.LogLevel) -> Color {
        switch level {
        case .info: return .gray
        case .step: return .yellow
        case .ok: return .green
        case .err: return .red
        }
    }

    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(converter.results, id: \.name) { result in
                resultItem(result)
            }

            if converter.results.count > 1 {
                Button(action: downloadAll) {
                    Text("下载全部")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(24)
                }
                .padding(.top, 8)
            }
        }
    }

    private func resultItem(_ result: ConversionResult) -> some View {
        HStack {
            Text(result.name)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Text(result.sizeDescription)
                .font(.system(size: 12))
                .foregroundColor(.gray)

            Button(action: { downloadFile(result) }) {
                Text("DOWNLOAD")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .underline()
            }
        }
        .padding(16)
        .background(Color(white: 0.04))
        .cornerRadius(8)
    }

    // MARK: - Actions
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            selectedFiles = urls
            fileNames = urls.map { $0.lastPathComponent }
            converter.logs.removeAll()
            converter.results.removeAll()
            loadFontPreviews(from: urls)
        case .failure(let error):
            print("Error selecting files: \(error)")
        }
    }

    private func loadFontPreviews(from urls: [URL]) {
        loadedFontData = []

        for url in urls.prefix(3) {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                loadedFontData.append(data)
                print("Loaded font data: \(url.lastPathComponent), size: \(data.count) bytes")
            } catch {
                print("Error loading font: \(error)")
            }
        }
    }

    private func loadSavedTemplate() {
        if let saved = UserDefaults.standard.string(forKey: "iFont_outputTpl") {
            outputTemplate = saved
        }
        if let saved = UserDefaults.standard.string(forKey: "iFont_previewText") {
            previewText = saved
        }
        if UserDefaults.standard.object(forKey: "iFont_fontSize") != nil {
            fontSize = UserDefaults.standard.double(forKey: "iFont_fontSize")
        }
        if UserDefaults.standard.object(forKey: "iFont_fontWeight") != nil {
            fontWeight = UserDefaults.standard.double(forKey: "iFont_fontWeight")
        }
        if UserDefaults.standard.object(forKey: "iFont_fontLineHeight") != nil {
            fontLineHeight = UserDefaults.standard.double(forKey: "iFont_fontLineHeight")
        }
    }

    private func startConversion() {
        converter.logs.removeAll()
        converter.results.removeAll()
        showingLog = true

        guard !selectedFiles.isEmpty else { return }

        for url in selectedFiles {
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                converter.convert(
                    sourceData: data,
                    fileName: url.lastPathComponent,
                    mode: selectedMode,
                    outputFormat: selectedFormat,
                    outputTemplate: outputTemplate
                )
            } catch {
                converter.addLog(.err, "读取文件失败: \(error.localizedDescription)")
            }
        }
    }

    private func downloadFile(_ result: ConversionResult) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(result.name)
        do {
            try result.data.write(to: tempURL)
            shareItems = [tempURL]
            showingShareSheet = true
        } catch {
            print("Error saving file: \(error)")
        }
    }

    private func downloadAll() {
        var tempURLs: [URL] = []

        for result in converter.results {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(result.name)
            do {
                try result.data.write(to: tempURL)
                tempURLs.append(tempURL)
            } catch {
                print("Error saving file: \(error)")
            }
        }

        if !tempURLs.isEmpty {
            shareItems = tempURLs
            showingShareSheet = true
        }
    }

    // MARK: - Bottom Attribution
    private var bottomAttribution: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                Link(destination: URL(string: "https://github.com/hhse")!) {
                    HStack(spacing: 6) {
                        GitHubIcon(size: 14)
                        Text("GitHub")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                }

                Link(destination: URL(string: "https://t.me/TheBallnow")!) {
                    HStack(spacing: 6) {
                        TelegramIcon(size: 14)
                        Text("TheBall")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                }

                Link(destination: URL(string: "https://joia.cn/")!) {
                    HStack(spacing: 6) {
                        WeChatIcon(size: 14)
                        Text("mumu")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                }
            }

            Text("© 2026 iFont @huamidev")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.5))

            Text("基于 huami-iFont 开发")
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.3))
        }
        .padding(.top, 16)
    }
}
