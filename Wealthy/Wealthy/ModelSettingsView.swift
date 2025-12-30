import SwiftUI

struct ModelSettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @State private var localLLM = LocalLLMService.shared
    
    var body: some View {
        List {
            // MARK: - Ticker Language
            Section(header: Text(lm.t(.tickerLanguage))) {
                Picker(lm.t(.tickerLanguage), selection: Binding(
                    get: { localLLM.tickerLanguage },
                    set: { localLLM.setTickerLanguage($0) }
                )) {
                    Text(lm.t(.tickerJP)).tag("日本語")
                    Text(lm.t(.tickerEN)).tag("English")
                }
                .pickerStyle(.segmented)
            }
            
            // MARK: - Current Status
            Section(header: Text(lm.t(.currentStatus))) {
                VStack(alignment: .leading) {
                    Text("Status: \(localLLM.loadStatus)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    if localLLM.downloadProgress > 0 && localLLM.downloadProgress < 1.0 {
                        ProgressView(value: localLLM.downloadProgress)
                        Text("\(Int(localLLM.downloadProgress * 100))%")
                            .font(.caption)
                    }
                }
            }
            
            // MARK: - Installed Models
            Section(header: Text(lm.t(.installedModels))) {
                let installedModels = localLLM.availableModels.filter { localLLM.isInstalled(modelId: $0.id) }
                
                if installedModels.isEmpty {
                    Text(lm.t(.noInstalledModels))
                        .foregroundStyle(.gray)
                        .italic()
                } else {
                    ForEach(installedModels) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .font(.headline)
                                Text(model.repoId)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            
                            if localLLM.currentModelId == model.id {
                                HStack {
                                    if localLLM.loadStatus.contains("準備完了") || localLLM.loadStatus.contains("Ready") {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                            .transition(.scale)
                                    } else {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(localLLM.currentModelId == model.id ? lm.t(.active) : "")
                                        .font(.caption)
                                        .bold()
                                        .foregroundStyle(localLLM.loadStatus.contains("準備完了") ? .green : .secondary)
                                }
                            } else {
                                Button(lm.t(.select)) {
                                    Task {
                                        await localLLM.setModel(model)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if localLLM.currentModelId == model.id {
                                    localLLM.deleteModel()
                                } else {
                                    localLLM.deleteModel(id: model.id)
                                }
                            } label: {
                                Label(lm.t(.deleteModel), systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            // MARK: - Available (Not Installed)
            Section(header: Text(lm.t(.availableForDownload))) {
                let uninstalledModels = localLLM.availableModels.filter { !localLLM.isInstalled(modelId: $0.id) }
                
                if uninstalledModels.isEmpty {
                    Text("All available models are installed")
                        .foregroundStyle(.gray)
                        .italic()
                } else {
                    ForEach(uninstalledModels) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .font(.headline)
                                Text(model.repoId)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                            
                            Button(lm.t(.install)) {
                                localLLM.startBackgroundDownload(model: model)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section {
                 Text(lm.t(.uninstallSwipeTip))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .navigationTitle(lm.t(.aiModelManagement))
    }
}
