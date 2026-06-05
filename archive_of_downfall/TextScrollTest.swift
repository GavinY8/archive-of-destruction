import SwiftUI

struct DialogueLine: Hashable {
    let speaker: String
    let text: String
}

struct Dialogue: Decodable {
    let name: String
    let text: String
}

struct StoryData: Decodable {
    let tutorial: [Dialogue]
    let story1: [Dialogue]
}

struct VisualNovelTextBoxView: View {
    @State private var script: [DialogueLine] = []
    @State private var currentLineIndex = 0
    @State private var displayedText = ""
    @State private var isTypingComplete = false
    @State private var typingTask: Task<Void, Never>? = nil
    
    @State private var currentScene = "tutorial"
    @State private var showHistoryLog = false
    
    // FIX: Changed prefix calculation to include the current active line position
    var dialogueHistory: [DialogueLine] {
        guard !script.isEmpty else { return [] }
        
        // If the story is finished, return the whole script array
        if currentLineIndex >= script.count {
            return script
        }
        
        // Grab everything up to AND including the current line index (+1)
        return Array(script.prefix(currentLineIndex + 1))
    }
    
    var conditionalDialogue: Text {
        if isTypingComplete {
            return Text("\(displayedText) \(Image(systemName: "arrowshape.forward.fill"))")
        } else {
            return Text(displayedText)
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { handleScreenTap() }
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: { showHistoryLog = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Log")
                        }
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .foregroundColor(.white)
                        .background(Capsule().fill(Color.black.opacity(0.6)))
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10) {
                    if !script.isEmpty && currentLineIndex < script.count {
                        Text(script[currentLineIndex].speaker)
                            .font(.headline)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-30))
                            .offset(x: -20, y: -20)
                            .padding(.top, 30)
                        
                        conditionalDialogue
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .offset(x: 30, y: -20)
                    } else {
                        Text(script.isEmpty ? "Loading Story..." : "Story Finished")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(0.85))
                        .overlay(VStack { Color.white.frame(height: 2); Spacer() })
                        .ignoresSafeArea(edges: [.horizontal, .bottom])
                )
            }
        }
        .task {
            loadStoryData(for: currentScene)
        }
        .sheet(isPresented: $showHistoryLog) {
            DialogueHistoryView(historyLines: dialogueHistory, currentLineIndex: currentLineIndex)
        }
    }
    
    func loadStoryData(for sceneName: String) {
        guard let fileURL = Bundle.main.url(forResource: "data", withExtension: "json") else {
            print("Error: data.json file not found in bundle.")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decodedData = try JSONDecoder().decode(StoryData.self, from: jsonData)
            
            let chosenDialogue: [Dialogue]
            switch sceneName {
            case "tutorial":
                chosenDialogue = decodedData.tutorial
            case "story1":
                chosenDialogue = decodedData.story1
            default:
                return
            }
            
            let loadedLines = chosenDialogue.map { item in
                DialogueLine(speaker: item.name, text: item.text)
            }
            
            self.currentLineIndex = 0
            self.script = loadedLines
            startTyping()
            
        } catch {
            print("Error parsing JSON data: \(error)")
        }
    }
    
    func startTyping() {
        guard currentLineIndex < script.count else { return }
        displayedText = ""
        isTypingComplete = false
        let fullText = script[currentLineIndex].text
        
        typingTask = Task {
            for character in fullText {
                if Task.isCancelled { break }
                displayedText.append(character)
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
            isTypingComplete = true
        }
    }
    
    func handleScreenTap() {
        guard currentLineIndex < script.count else { return }
        if !isTypingComplete {
            typingTask?.cancel()
            displayedText = script[currentLineIndex].text
            isTypingComplete = true
        } else {
            currentLineIndex += 1
            
            if currentLineIndex >= script.count && currentScene == "tutorial" {
                currentScene = "story1"
                loadStoryData(for: "story1")
            } else {
                startTyping()
            }
        }
    }
}

struct DialogueHistoryView: View {
    let historyLines: [DialogueLine]
    let currentLineIndex: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if historyLines.isEmpty {
                            Text("No dialogue spoken yet.")
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 40)
                        } else {
                            // Cleaned up loop layout by index
                            ForEach(0..<historyLines.count, id: \.self) { index in
                                let line = historyLines[index]
                                
                                // FIX: Moved the complex rows into a dedicated sub-view below
                                DialogueLogRow(
                                    line: line,
                                    index: index,
                                    currentLineIndex: currentLineIndex
                                )
                                .id(index)
                                
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Dialogue Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { dismiss() }
                    }
                }
                .onAppear {
                    if !historyLines.isEmpty {
                        proxy.scrollTo(historyLines.count - 1, anchor: .bottom)
                    }
                }
            }
        }
    }
}

// NEW SUB-VIEW: Isolates processing logic so the compiler compiles instantly
struct DialogueLogRow: View {
    let line: DialogueLine
    let index: Int
    let currentLineIndex: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(line.speaker)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                
                Text(line.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .opacity(index == currentLineIndex ? 1.0 : 0.75)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    VisualNovelTextBoxView()
}
