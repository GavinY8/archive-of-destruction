import SwiftUI

struct DialogueLine {
    let speaker: String
    let text: String
}

struct VisualNovelTextBoxView: View {
    let script: [DialogueLine] = [
        DialogueLine(speaker: "Hero", text: "What is this place? I can't remember anything..."),
        DialogueLine(speaker: "???", text: "Welcome to your new story. Tap to continue..."),
        DialogueLine(speaker: "Hero", text: "Who said that?! Show yourself!")
    ]
    
    @State private var currentLineIndex = 0
    @State private var displayedText = ""
    @State private var isTypingComplete = false
    @State private var typingTask: Task<Void, Never>? = nil
    
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
            
            VStack {
                Spacer()
                
                // Visual Novel Text Box Container
                VStack(alignment: .leading, spacing: 10) {
                    if currentLineIndex < script.count {
                        Text(script[currentLineIndex].speaker)
                            .font(.headline)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-30))
                            .offset(x:-20, y:-20)
                            .padding(.top, 30)
                        
                        conditionalDialogue
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .offset(x:10, y: -20)
                    } else {
                        Text("Story Finished")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                // Added bottom padding so the dialogue text stays readable above the device screen home bar
                .padding(.bottom, 20)
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(0.85))
                        .overlay(VStack { Color.white.frame(height: 2); Spacer() })
                        // FIX: Added .bottom here to force background to fill the lower notch area
                        .ignoresSafeArea(edges: [.horizontal, .bottom])
                )
            }
        }
        .onTapGesture { handleScreenTap() }
        .onAppear { startTyping() }
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
            startTyping()
        }
    }
}

#Preview {
    VisualNovelTextBoxView()
}
