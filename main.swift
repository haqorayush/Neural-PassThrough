import SwiftUI
import AVFoundation
import CoreAudio
import ServiceManagement
import Carbon.HIToolbox

// MARK: - App Entry Point
@main
struct TransparencyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioController = AudioController()

    var body: some Scene {
        // Slim Menu Bar — on/off toggle only
        MenuBarExtra(content: {
            MenuBarView(audioController: audioController)
        }, label: {
            Image(systemName: audioController.isActive ? "waveform.path.ecg" : "waveform.path")
                .renderingMode(.template)
                .symbolRenderingMode(.monochrome)
        })
        .menuBarExtraStyle(.window)
        
        // Full Settings Window
        Window("Neural PassThrough", id: "settings") {
            SettingsWindowView(audioController: audioController)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 880, height: 600)
        .windowResizability(.contentSize)
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Reset legacy window frame if stored
        if let frameString = UserDefaults.standard.string(forKey: "NSWindow Frame settings") {
            let parts = frameString.split(separator: " ")
            if parts.count >= 4, let w = Double(parts[2]), (w < 800 || (Double(parts[3]) ?? 0) > 650) {
                UserDefaults.standard.removeObject(forKey: "NSWindow Frame settings")
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }
}

func showSettingsWindow() {
    NSApp.setActivationPolicy(.regular)
    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("settings") ?? false }) {
        window.isMovableByWindowBackground = true
        if window.frame.width < 800 || window.frame.height > 650 {
            var frame = window.frame
            frame.size.width = 880
            frame.size.height = 600
            window.setFrame(frame, display: true, animate: false)
        }
        window.makeKeyAndOrderFront(nil)
    } else {
        // Open via SwiftUI environment
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    NSApp.activate(ignoringOtherApps: true)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Menu Bar View (Slim — On/Off Only)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct MenuBarView: View {
    @ObservedObject var audioController: AudioController
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(audioController.isActive ? .cyan : .gray)
                    .symbolEffect(.pulse, options: .repeating, isActive: audioController.isActive)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEURAL PASSTHROUGH")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(audioController.isActive ? .cyan : .gray)
                        .tracking(1.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(audioController.statusText)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(audioController.errorMessage != nil ? .red : .secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $audioController.isActive)
                    .toggleStyle(.switch)
                    .tint(.cyan)
                    .labelsHidden()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.4))
            
            // Error Banner
            if let error = audioController.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
            }
            
            // Quick Stats (when active)
            if audioController.isActive {
                HStack(spacing: 12) {
                    QuickStat(label: "LATENCY", value: String(format: "%.2fms", audioController.latency * 1000.0))
                    QuickStat(label: "SIGNAL", value: String(format: "%.1fdB", audioController.audioLevelDb))
                    QuickStat(label: "MODE", value: audioController.micModeShort, tint: micModeColor(for: audioController.micModeName))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
            }
            
            // Open Settings + Quit
            HStack {
                Button(action: {
                    openWindow(id: "settings")
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("SETTINGS")
                            .tracking(0.5)
                    }
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    audioController.shutdown()
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                        Text("QUIT")
                            .tracking(0.5)
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.4))
        }
        .frame(width: 280)
        .background(Material.ultraThin)
        .environment(\.colorScheme, .dark)
    }
}

struct QuickStat: View {
    let label: String
    let value: String
    var tint: Color = .cyan
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Settings Window (Symmetric 2×2 Layout)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct SettingsWindowView: View {
    @ObservedObject var audioController: AudioController
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ── Title Bar ──
                WindowHeader(audioController: audioController)
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // ── Symmetric 2x2 Grid ──
                ScrollView(.vertical, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        // ── Left Column: Audio Engine & Signal Monitoring ──
                        VStack(spacing: 16) {
                            AudioEngineCard(audioController: audioController)
                                .frame(minHeight: 295)
                            
                            SignalAndAmplificationCard(audioController: audioController)
                                .frame(minHeight: 185)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        
                        // ── Right Column: DSP Processing & System Preferences ──
                        VStack(spacing: 16) {
                            MicModeCard(audioController: audioController)
                                .frame(minHeight: 295)
                            
                            PreferencesCard(audioController: audioController)
                                .frame(minHeight: 185)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 840, idealWidth: 880, maxWidth: 940, minHeight: 570, idealHeight: 600, maxHeight: 660)
        .environment(\.colorScheme, .dark)
        .onAppear {
            if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("settings") ?? false }) {
                window.isMovableByWindowBackground = true
                if window.frame.width < 800 || window.frame.height > 650 {
                    var frame = window.frame
                    frame.size.width = 880
                    frame.size.height = 600
                    window.setFrame(frame, display: true, animate: false)
                }
            }
        }
    }
}

// MARK: - Window Header
struct WindowHeader: View {
    @ObservedObject var audioController: AudioController
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(audioController.isActive ? .cyan : .gray)
                .symbolEffect(.pulse, options: .repeating, isActive: audioController.isActive)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("NEURAL PASSTHROUGH")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(audioController.isActive ? .cyan : .gray)
                    .tracking(2)
                
                Text(audioController.statusText)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(audioController.errorMessage != nil ? .red : .secondary)
            }
            
            Spacer()
            
            // Uptime badge
            if audioController.isActive {
                Text(audioController.uptimeString)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.08))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03))
    }
}

// MARK: - Section Card Container
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    var badge: String? = nil
    var badgeColor: Color = .cyan
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.cyan.opacity(0.7))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(1.5)
                
                Spacer()
                
                if let badge = badge {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(badgeColor)
                            .frame(width: 5, height: 5)
                        Text(badge)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(badgeColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.08))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(badgeColor.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Top-Left: Audio Engine & Hardware Card
struct AudioEngineCard: View {
    @ObservedObject var audioController: AudioController
    
    var body: some View {
        SectionCard(
            title: "AUDIO ENGINE & HARDWARE",
            icon: "cpu",
            badge: audioController.isActive ? "ONLINE" : "STANDBY",
            badgeColor: audioController.isActive ? .cyan : .gray
        ) {
            VStack(spacing: 12) {
                // Power Toggle Panel
                HStack(spacing: 14) {
                    Button(action: { audioController.isActive.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(audioController.isActive ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle()
                                        .stroke(audioController.isActive ? Color.cyan.opacity(0.6) : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                            
                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(audioController.isActive ? .cyan : .gray)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(audioController.isActive ? "TRANSPARENCY ACTIVE" : "TRANSPARENCY OFFLINE")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(audioController.isActive ? .cyan : .gray)
                        
                        Text("⌥⇧T to toggle anywhere")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        if let error = audioController.errorMessage {
                            Text(error)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.white.opacity(0.02))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(audioController.isActive ? Color.cyan.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
                )
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // Telemetry 2x3 Grid
                TelemetryGrid(audioController: audioController)
            }
        }
    }
}

// MARK: - Top-Right: Microphone DSP Mode Card
struct MicModeCard: View {
    @ObservedObject var audioController: AudioController
    
    var body: some View {
        SectionCard(
            title: "MICROPHONE MODE",
            icon: "mic.fill",
            badge: audioController.micModeShort,
            badgeColor: micModeColor(for: audioController.micModeName)
        ) {
            VStack(alignment: .leading, spacing: 10) {
                // Active Mode Banner
                HStack(spacing: 8) {
                    Circle()
                        .fill(micModeColor(for: audioController.micModeName))
                        .frame(width: 8, height: 8)
                        .shadow(color: micModeColor(for: audioController.micModeName).opacity(0.6), radius: 4)
                    
                    Text(audioController.micModeName)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(micModeColor(for: audioController.micModeName))
                    
                    Spacer()
                }
                
                // Mode Selection Buttons
                VStack(alignment: .leading, spacing: 6) {
                    ModeRow(name: "STANDARD", desc: "Balanced voice clarity with light noise reduction", color: .cyan, isActive: audioController.micModeName == "STANDARD") {
                        audioController.setMicMode("STANDARD")
                    }
                    ModeRow(name: "VOICE ISOLATION", desc: "Apple ML neural background noise cancellation", color: .purple, isActive: audioController.micModeName == "VOICE ISOLATION") {
                        audioController.setMicMode("VOICE ISOLATION")
                    }
                    ModeRow(name: "WIDE SPECTRUM", desc: "Pure acoustic transparency — captures all ambient sounds", color: .green, isActive: audioController.micModeName == "WIDE SPECTRUM") {
                        audioController.setMicMode("WIDE SPECTRUM")
                    }
                }
                
                // macOS Control Center Button
                Button(action: {
                    audioController.showMicModePicker()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.2.square")
                            .font(.system(size: 11))
                        Text("OPEN MACOS CONTROL CENTER")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(.gray)
                
                Text("Click any mode above to switch DSP audio processing.")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Bottom-Left: Signal Meter & Amplification Card
struct SignalAndAmplificationCard: View {
    @ObservedObject var audioController: AudioController
    
    var body: some View {
        SectionCard(
            title: "SIGNAL & AMPLIFICATION",
            icon: "waveform",
            badge: audioController.isActive ? String(format: "%.0f%%", audioController.volume * 100) : nil,
            badgeColor: volumeColor(for: audioController.volume)
        ) {
            VStack(spacing: 12) {
                // Signal Meter
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("INPUT SIGNAL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if audioController.isActive {
                            Text(String(format: "%.1f dB", audioController.audioLevelDb))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(audioController.audioLevel > 0.8 ? .red : .cyan)
                        } else {
                            Text("AWAITING SIGNAL")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    
                    // Level bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 8)
                            
                            if audioController.isActive {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.cyan, audioController.audioLevel > 0.6 ? .yellow : .cyan, audioController.audioLevel > 0.8 ? .red : .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, geometry.size.width * CGFloat(audioController.audioLevel)), height: 8)
                                    .animation(.easeOut(duration: 0.08), value: audioController.audioLevel)
                            }
                        }
                    }
                    .frame(height: 8)
                }
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // Amplification Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("OUTPUT GAIN")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f%%", audioController.volume * 100))
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(volumeColor(for: audioController.volume))
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        
                        Slider(value: $audioController.volume, in: 0.0...2.0)
                            .tint(volumeColor(for: audioController.volume))
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    if audioController.volume > 1.0 {
                        HStack(spacing: 6) {
                            Image(systemName: audioController.volume > 1.5 ? "ear.trianglebadge.exclamationmark" : "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(audioController.volume > 1.5 ? "HEARING DAMAGE RISK" : "CLIPPING POSSIBLE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(audioController.volume > 1.5 ? .red : .orange)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((audioController.volume > 1.5 ? Color.red : Color.orange).opacity(0.08))
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
    
    private func volumeColor(for vol: Float) -> Color {
        if vol > 1.5 { return .red }
        if vol > 1.0 { return .orange }
        return .cyan
    }
}

// MARK: - Bottom-Right: System Preferences Card
struct PreferencesCard: View {
    @ObservedObject var audioController: AudioController
    
    var body: some View {
        SectionCard(
            title: "PREFERENCES",
            icon: "gearshape.fill",
            badge: "CONFIG",
            badgeColor: .gray
        ) {
            VStack(spacing: 10) {
                // Launch at Login
                HStack {
                    Button(action: { audioController.toggleLaunchAtLogin() }) {
                        HStack(spacing: 8) {
                            Image(systemName: audioController.launchAtLogin ? "checkmark.square.fill" : "square")
                                .font(.system(size: 14))
                                .foregroundColor(audioController.launchAtLogin ? .cyan : .gray)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("LAUNCH AT LOGIN")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Start automatically when you log in")
                                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // Global Hotkey Info
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("GLOBAL HOTKEY")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Text("⌥⇧T — Toggle transparency anywhere")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .background(Color.white.opacity(0.06))
                
                // Shutdown Button
                HStack {
                    Spacer()
                    Button(action: {
                        audioController.shutdown()
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                            Text("SHUTDOWN")
                                .tracking(1)
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.red.opacity(0.7))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.06))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Telemetry Grid
struct TelemetryGrid: View {
    @ObservedObject var audioController: AudioController
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            InfoBox(title: "INPUT", value: audioController.inputDeviceName.uppercased(), tint: .cyan)
            InfoBox(title: "OUTPUT", value: audioController.outputDeviceName.uppercased(), tint: .cyan)
            InfoBox(title: "SAMPLE RATE", value: audioController.isActive ? String(format: "%.1f kHz", audioController.sampleRate / 1000.0) : "—", tint: .teal)
            InfoBox(title: "CHANNELS", value: audioController.isActive ? "\(audioController.channels)" : "—", tint: .teal)
            InfoBox(title: "FORMAT", value: audioController.isActive ? audioController.formatString : "—", tint: .mint)
            InfoBox(title: "LATENCY", value: audioController.isActive ? String(format: "%.2f ms", audioController.latency * 1000.0) : "—", tint: .mint)
        }
        .opacity(audioController.isActive ? 1.0 : 0.35)
    }
}

struct InfoBox: View {
    let title: String
    let value: String
    var tint: Color = .cyan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: 42)
        .padding(8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ModeRow: View {
    let name: String
    let desc: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? color : color.opacity(0.2))
                    .frame(width: 3, height: 26)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isActive ? color : .gray)
                    Text(desc)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(color)
                }
            }
            .padding(7)
            .background(isActive ? color.opacity(0.08) : Color.white.opacity(0.02))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers
func micModeColor(for mode: String) -> Color {
    switch mode {
    case "WIDE SPECTRUM": return .green
    case "VOICE ISOLATION": return .purple
    case "STANDARD": return .cyan
    default: return .gray
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Global Hotkey (⌥⇧T)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class HotkeyManager {
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void
    
    init(callback: @escaping () -> Void) {
        self.callback = callback
        registerHotkey()
    }
    
    deinit {
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
    
    private func registerHotkey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x54525053), id: 1) // "TRPS"
        var hotKeyRef: EventHotKeyRef?
        
        let modifiers: UInt32 = UInt32(optionKey | shiftKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_T), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let mgr = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                mgr.callback()
            }
            return noErr
        }, 1, &eventType, selfPtr, &eventHandler)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Audio Controller
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AudioController: NSObject, ObservableObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var isActive = false {
        didSet {
            if isActive != oldValue {
                if isActive { start() } else { stop() }
            }
        }
    }
    @Published var volume: Float = 1.0 {
        didSet {
            if engine.isRunning {
                engine.mainMixerNode.outputVolume = volume
            }
        }
    }
    @Published var sampleRate: Double = 0.0
    @Published var channels: Int = 0
    @Published var inputDeviceName: String = "—"
    @Published var outputDeviceName: String = "—"
    @Published var formatString: String = "—"
    @Published var latency: TimeInterval = 0.0
    @Published var audioLevel: Float = 0.0
    @Published var audioLevelDb: Float = -60.0
    @Published var errorMessage: String? = nil
    @Published var launchAtLogin: Bool = false
    @Published var uptimeString: String = "00:00:00"
    @Published var micModeName: String = "WIDE SPECTRUM"
    
    var statusText: String {
        if let err = errorMessage { return err }
        return isActive ? "SYSTEM ONLINE" : "STANDBY"
    }
    
    var micModeShort: String {
        switch micModeName {
        case "WIDE SPECTRUM": return "WIDE"
        case "VOICE ISOLATION": return "VOICE"
        case "STANDARD": return "STD"
        default: return "—"
        }
    }
    
    private var telemetryTimer: Timer?
    private var hotkeyManager: HotkeyManager?
    private var sessionStartTime: Date?

    private var engine = AVAudioEngine()
    private var captureSession = AVCaptureSession()
    private let captureAudioOutput = AVCaptureAudioDataOutput()
    private let captureQueue = DispatchQueue(label: "com.ayush.captureSessionQueue", qos: .userInitiated)
    private var rawMixer = AVAudioMixerNode()
    private var processedMixer = AVAudioMixerNode()
    private var soundIsolationNode: AVAudioUnitEffect?
    private var eqNode: AVAudioUnitEQ?
    private var isWired = false
    private var hasTap = false
    private var isObservingMicMode = false

    override init() {
        super.init()
        setupAudioSession()
        updateDeviceNames()
        setupSystemMicModeObserver()
        syncMicModeFromSystem()
        checkLaunchAtLogin()
        
        hotkeyManager = HotkeyManager { [weak self] in
            guard let self = self else { return }
            self.isActive.toggle()
        }
        
        NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] _ in
            self?.handleConfigurationChange()
        }
    }
    
    deinit {
        removeSystemMicModeObserver()
        telemetryTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func handleConfigurationChange() {
        if isActive {
            let wasActive = isActive
            stopTelemetry()
            engine.stop()
            removeTap()
            engine = AVAudioEngine()
            rawMixer = AVAudioMixerNode()
            processedMixer = AVAudioMixerNode()
            soundIsolationNode = nil
            eqNode = nil
            isWired = false
            hasTap = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, wasActive else { return }
                self.startEngine()
            }
        }
    }

    func setupAudioSession() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            errorMessage = nil
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.errorMessage = granted ? nil : "MIC ACCESS DENIED"
                }
            }
        case .denied, .restricted:
            errorMessage = "MIC ACCESS DENIED"
        @unknown default:
            break
        }
    }
    
    private func updateDeviceNames() {
        inputDeviceName = getDeviceName(isInput: true)
        outputDeviceName = getDeviceName(isInput: false)
    }

    func toggle() {
        isActive.toggle()
    }
    
    // MARK: - Launch at Login
    func toggleLaunchAtLogin() {
        launchAtLogin.toggle()
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = !launchAtLogin
        }
    }
    
    private func checkLaunchAtLogin() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }
    
    // MARK: - Mic Mode Integration
    func setMicMode(_ mode: String) {
        micModeName = mode
        applyMicModeDSP()
    }
    
    private func applyMicModeDSP() {
        switch micModeName {
        case "WIDE SPECTRUM":
            // True Wide Spectrum: 100% direct raw hardware mic audio, 0% neural filter
            rawMixer.outputVolume = 1.0
            processedMixer.outputVolume = 0.0
            soundIsolationNode?.bypass = true
            eqNode?.bands[0].bypass = true
            
        case "VOICE ISOLATION":
            // 100% Apple Neural Voice Isolation
            rawMixer.outputVolume = 0.0
            processedMixer.outputVolume = 1.0
            if let isolation = soundIsolationNode {
                isolation.bypass = false
                if let param = isolation.auAudioUnit.parameterTree?.parameter(withAddress: 0) {
                    param.value = 100.0
                }
            }
            if let eq = eqNode {
                eq.bands[0].frequency = 100.0
                eq.bands[0].bypass = false
            }
            
        case "STANDARD":
            // Balanced voice processing
            rawMixer.outputVolume = 0.0
            processedMixer.outputVolume = 1.0
            if let isolation = soundIsolationNode {
                isolation.bypass = false
                if let param = isolation.auAudioUnit.parameterTree?.parameter(withAddress: 0) {
                    param.value = 35.0
                }
            }
            if let eq = eqNode {
                eq.bands[0].bypass = true
            }
            
        default:
            rawMixer.outputVolume = 1.0
            processedMixer.outputVolume = 0.0
        }
    }
    
    private func setupSystemMicModeObserver() {
        guard !isObservingMicMode else { return }
        (AVCaptureDevice.self as NSObject.Type).addObserver(self, forKeyPath: "preferredMicrophoneMode", options: [.new], context: nil)
        (AVCaptureDevice.self as NSObject.Type).addObserver(self, forKeyPath: "activeMicrophoneMode", options: [.new], context: nil)
        isObservingMicMode = true
    }
    
    private func removeSystemMicModeObserver() {
        if isObservingMicMode {
            (AVCaptureDevice.self as NSObject.Type).removeObserver(self, forKeyPath: "preferredMicrophoneMode")
            (AVCaptureDevice.self as NSObject.Type).removeObserver(self, forKeyPath: "activeMicrophoneMode")
            isObservingMicMode = false
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "preferredMicrophoneMode" || keyPath == "activeMicrophoneMode" {
            DispatchQueue.main.async { [weak self] in
                self?.syncMicModeFromSystem()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func syncMicModeFromSystem() {
        let mode = AVCaptureDevice.preferredMicrophoneMode
        let mapped: String
        switch mode {
        case .standard: mapped = "STANDARD"
        case .wideSpectrum: mapped = "WIDE SPECTRUM"
        case .voiceIsolation: mapped = "VOICE ISOLATION"
        @unknown default:
            let act = AVCaptureDevice.activeMicrophoneMode
            switch act {
            case .wideSpectrum: mapped = "WIDE SPECTRUM"
            case .voiceIsolation: mapped = "VOICE ISOLATION"
            default: mapped = "STANDARD"
            }
        }
        if micModeName != mapped {
            micModeName = mapped
            applyMicModeDSP()
        }
    }
    
    func showMicModePicker() {
        NSApp.activate(ignoringOtherApps: true)
        AVCaptureDevice.showSystemUserInterface(.microphoneModes)
    }
    
    // MARK: - Device Name via CoreAudio
    private func getDeviceName(isInput: Bool) -> String {
        var deviceID = kAudioObjectUnknown
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: isInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        
        if status != noErr || deviceID == kAudioObjectUnknown { return "NONE" }
        
        var name: CFString = "" as CFString
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        status = withUnsafeMutablePointer(to: &name) { ptr in
            AudioObjectGetPropertyData(
                deviceID,
                &nameAddress,
                0,
                nil,
                &nameSize,
                ptr
            )
        }
        
        return status == noErr ? (name as String) : "UNKNOWN"
    }

    private func formatName(for format: AVAudioCommonFormat) -> String {
        switch format {
        case .pcmFormatFloat32: return "32-BIT FLOAT"
        case .pcmFormatFloat64: return "64-BIT FLOAT"
        case .pcmFormatInt16: return "16-BIT INT"
        case .pcmFormatInt32: return "32-BIT INT"
        default: return "OTHER"
        }
    }

    // MARK: - Engine Lifecycle
    private func start() {
        errorMessage = nil
        startCaptureSession()
        startEngine()
    }
    
    private func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.beginConfiguration()
                self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
                self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
                if let mic = AVCaptureDevice.default(for: .audio),
                   let input = try? AVCaptureDeviceInput(device: mic),
                   self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                }
                if self.captureSession.canAddOutput(self.captureAudioOutput) {
                    self.captureAudioOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
                    self.captureSession.addOutput(self.captureAudioOutput)
                }
                self.captureSession.commitConfiguration()
                self.captureSession.startRunning()
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Keeps capture pipeline active for system Control Center
    }
    
    private func stopCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func startEngine() {
        if !isWired {
            let input = engine.inputNode
            let inputFormat = input.inputFormat(forBus: 0)
            
            guard inputFormat.sampleRate > 0 else {
                errorMessage = "NO INPUT DEVICE"
                isActive = false
                return
            }
            
            // Attach mixers
            engine.attach(rawMixer)
            engine.attach(processedMixer)
            
            // Setup Path B (Neural Sound Isolation + EQ -> processedMixer -> Main Mixer)
            let desc = AudioComponentDescription(
                componentType: kAudioUnitType_Effect,
                componentSubType: kAudioUnitSubType_AUSoundIsolation,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
            
            let eq = AVAudioUnitEQ(numberOfBands: 1)
            eq.bands[0].filterType = .highPass
            eq.bands[0].frequency = 100.0
            eq.bands[0].bypass = false
            self.eqNode = eq
            engine.attach(eq)
            
            var isolationCreated = false
            let semaphore = DispatchSemaphore(value: 0)
            AVAudioUnitEffect.instantiate(with: desc, options: []) { [weak self] unit, error in
                if let isolation = unit as? AVAudioUnitEffect {
                    self?.soundIsolationNode = isolation
                    self?.engine.attach(isolation)
                    isolationCreated = true
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 1.0)
            
            // Dual-bus fan-out from hardware microphone input
            if isolationCreated, let isolation = soundIsolationNode {
                let cpRaw = AVAudioConnectionPoint(node: rawMixer, bus: 0)
                let cpIso = AVAudioConnectionPoint(node: isolation, bus: 0)
                engine.connect(input, to: [cpRaw, cpIso], fromBus: 0, format: inputFormat)
                
                // Path B: isolation -> eq -> processedMixer -> mainMixerNode
                engine.connect(isolation, to: eq, format: inputFormat)
                engine.connect(eq, to: processedMixer, format: inputFormat)
                engine.connect(processedMixer, to: engine.mainMixerNode, format: inputFormat)
            } else {
                // Fallback: connect directly to rawMixer
                engine.connect(input, to: rawMixer, format: inputFormat)
            }
            
            // Path A: rawMixer -> mainMixerNode
            engine.connect(rawMixer, to: engine.mainMixerNode, format: inputFormat)
            
            isWired = true
            
            sampleRate = inputFormat.sampleRate
            channels = Int(inputFormat.channelCount)
            formatString = formatName(for: inputFormat.commonFormat)
            
            // Apply mode routing immediately
            applyMicModeDSP()
            
            // Install audio level tap
            installLevelTap(format: inputFormat)
        }
        
        engine.mainMixerNode.outputVolume = volume

        do {
            try engine.start()
            if !isActive { isActive = true }
            sessionStartTime = Date()
            startTelemetry()
        } catch {
            errorMessage = "ENGINE FAILED"
            isActive = false
        }
    }
    
    private func stop() {
        removeTap()
        engine.stop()
        stopCaptureSession()
        stopTelemetry()
        isWired = false
        hasTap = false
        sessionStartTime = nil
        audioLevel = 0.0
        audioLevelDb = -60.0
        uptimeString = "00:00:00"
    }
    
    func shutdown() {
        if isActive {
            removeTap()
            engine.stop()
            stopTelemetry()
        }
    }
    
    // MARK: - Audio Level Metering
    private func installLevelTap(format: AVAudioFormat) {
        let tapFormat = AVAudioFormat(standardFormatWithSampleRate: format.sampleRate, channels: 1) ?? format
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            
            var sum: Float = 0.0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            let db = 20.0 * log10(max(rms, 0.000001))
            
            let normalized = max(0.0, min(1.0, (db + 60.0) / 60.0))
            
            DispatchQueue.main.async {
                if normalized >= self.audioLevel {
                    self.audioLevel = normalized
                } else {
                    self.audioLevel = max(normalized, self.audioLevel * 0.85)
                }
                self.audioLevelDb = db
            }
        }
        hasTap = true
    }
    
    private func removeTap() {
        if hasTap {
            engine.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
    }
    
    // MARK: - Real-Time Telemetry
    private func startTelemetry() {
        telemetryTimer?.invalidate()
        pollTelemetry()
        
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.pollTelemetry()
        }
        RunLoop.main.add(timer, forMode: .common)
        telemetryTimer = timer
    }
    
    private func pollTelemetry() {
        guard isActive else { return }
        
        let inDev = getDeviceName(isInput: true)
        let outDev = getDeviceName(isInput: false)
        
        let currentFormat = engine.inputNode.inputFormat(forBus: 0)
        let sr = currentFormat.sampleRate
        let ch = Int(currentFormat.channelCount)
        let fmt = formatName(for: currentFormat.commonFormat)
        
        // Clean latency calculation: 512-frame hardware buffer + output stage
        let calcLatency = (sr > 0) ? (512.0 / sr) : 0.005
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latency = calcLatency
            if self.inputDeviceName != inDev { self.inputDeviceName = inDev }
            if self.outputDeviceName != outDev { self.outputDeviceName = outDev }
            if self.sampleRate != sr { self.sampleRate = sr }
            if self.channels != ch { self.channels = ch }
            if self.formatString != fmt { self.formatString = fmt }
            
            if let start = self.sessionStartTime {
                let elapsed = Int(Date().timeIntervalSince(start))
                let h = elapsed / 3600
                let m = (elapsed % 3600) / 60
                let s = elapsed % 60
                self.uptimeString = String(format: "%02d:%02d:%02d", h, m, s)
            }
        }
    }
    
    private func stopTelemetry() {
        telemetryTimer?.invalidate()
        telemetryTimer = nil
    }
}
