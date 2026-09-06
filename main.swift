import SwiftUI
import AVFoundation
import CoreAudio
import ServiceManagement
import Carbon.HIToolbox

@main
struct TransparencyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioController = AudioController()

    var body: some Scene {
        MenuBarExtra(content: {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(audioController.isActive ? .cyan : .gray)
                        .symbolEffect(.pulse, options: .repeating, isActive: audioController.isActive)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NEURAL PASSTHROUGH")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(audioController.isActive ? .cyan : .gray)
                            .tracking(2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(audioController.statusText)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundColor(audioController.errorMessage != nil ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $audioController.isActive)
                        .toggleStyle(.switch)
                        .tint(.cyan)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.4))
                
                // Error Banner
                if let error = audioController.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.red)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                }
                
                VStack(spacing: 16) {
                    // Detailed Hardware Info (2x3 Grid) — always visible
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        // Row 1: Devices
                        InfoBox(title: "INPUT", value: audioController.inputDeviceName.uppercased(), tint: .cyan)
                        InfoBox(title: "OUTPUT", value: audioController.outputDeviceName.uppercased(), tint: .cyan)
                        
                        // Row 2: Stream specs
                        InfoBox(title: "SAMPLE RATE", value: audioController.isActive ? String(format: "%.1f kHz", audioController.sampleRate / 1000.0) : "—", tint: .teal)
                        InfoBox(title: "CHANNELS", value: audioController.isActive ? "\(audioController.channels)" : "—", tint: .teal)
                        
                        // Row 3: Performance
                        InfoBox(title: "FORMAT", value: audioController.isActive ? audioController.formatString : "—", tint: .mint)
                        InfoBox(title: "LATENCY", value: audioController.isActive ? String(format: "%.2f ms", audioController.latency * 1000.0) : "—", tint: .mint)
                    }
                    .opacity(audioController.isActive ? 1.0 : 0.35)
                    
                    // Audio Level Meter + Uptime
                    if audioController.isActive {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("SIGNAL")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(format: "%.1f dB", audioController.audioLevelDb))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(audioController.audioLevel > 0.8 ? .red : .cyan)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(meterGradient(level: audioController.audioLevel))
                                        .frame(width: max(0, geometry.size.width * CGFloat(audioController.audioLevel)), height: 6)
                                        .animation(.easeOut(duration: 0.08), value: audioController.audioLevel)
                                }
                            }
                            .frame(height: 6)
                        }
                        
                        // Uptime
                        HStack {
                            Text("UPTIME")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(audioController.uptimeString)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.7))
                        }
                    }
                    
                    // Volume Slider
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("AMPLIFICATION")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.0f%%", audioController.volume * 100))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(volumeColor(for: audioController.volume))
                        }
                        
                        Slider(value: $audioController.volume, in: 0.0...2.0)
                            .tint(volumeColor(for: audioController.volume))
                        
                        if audioController.volume > 1.0 {
                            HStack(spacing: 4) {
                                Image(systemName: audioController.volume > 1.5 ? "ear.trianglebadge.exclamationmark" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text(audioController.volume > 1.5 ? "HEARING DAMAGE RISK" : "CLIPPING POSSIBLE")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(audioController.volume > 1.5 ? .red : .orange)
                        }
                    }
                }
                .padding(16)
                .background(Color.black.opacity(0.2))
                
                // Footer
                HStack {
                    // Launch at Login Toggle
                    Button(action: {
                        audioController.toggleLaunchAtLogin()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: audioController.launchAtLogin ? "checkmark.square.fill" : "square")
                                .foregroundColor(audioController.launchAtLogin ? .cyan : .gray)
                            Text("AUTO-START")
                                .tracking(0.5)
                        }
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        audioController.shutdown()
                        NSApplication.shared.terminate(nil)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "power")
                            Text("SHUTDOWN")
                                .tracking(1)
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.4))
            }
            .frame(width: 300)
            .background(Material.ultraThin)
            .environment(\.colorScheme, .dark)
        }, label: {
            Image(systemName: audioController.isActive ? "waveform.path.ecg" : "waveform.path")
        })
        .menuBarExtraStyle(.window)
    }
    
    private func volumeColor(for vol: Float) -> Color {
        if vol > 1.5 { return .red }
        if vol > 1.0 { return .orange }
        return .cyan
    }
    
    private func meterGradient(level: Float) -> LinearGradient {
        LinearGradient(
            colors: [.cyan, level > 0.6 ? .yellow : .cyan, level > 0.8 ? .red : .cyan],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct InfoBox: View {
    let title: String
    let value: String
    var tint: Color = .cyan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 50)
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

// MARK: - Global Hotkey (⌥⇧T)
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
        var hotKeyID = EventHotKeyID(signature: OSType(0x54525053), id: 1) // "TRPS"
        var hotKeyRef: EventHotKeyRef?
        
        // ⌥⇧T: optionKey = 0x0800, shiftKey = 0x0200, 'T' = kVK_ANSI_T = 0x11
        let modifiers: UInt32 = UInt32(optionKey | shiftKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_T), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        // Install handler
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

// MARK: - Audio Controller
class AudioController: ObservableObject {
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
    
    var statusText: String {
        if let err = errorMessage { return err }
        return isActive ? "SYSTEM ONLINE" : "STANDBY"
    }
    
    private var telemetryTimer: Timer?
    private var hotkeyManager: HotkeyManager?
    private var sessionStartTime: Date?

    private var engine = AVAudioEngine()
    private var isWired = false
    private var hasTap = false

    init() {
        setupAudioSession()
        updateDeviceNames()
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
            launchAtLogin = !launchAtLogin // revert on failure
        }
    }
    
    private func checkLaunchAtLogin() {
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
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
        startEngine()
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
            
            // Route: Mic -> Mixer -> Earphones
            engine.connect(input, to: engine.mainMixerNode, format: inputFormat)
            isWired = true
            
            sampleRate = inputFormat.sampleRate
            channels = Int(inputFormat.channelCount)
            formatString = formatName(for: inputFormat.commonFormat)
            
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
        stopTelemetry()
        isWired = false
        hasTap = false
        sessionStartTime = nil
        audioLevel = 0.0
        audioLevelDb = -60.0
        uptimeString = "00:00:00"
    }
    
    /// Graceful shutdown: clean up engine before app termination
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
            
            // Clamp to 0...1 range for display (maps -60dB...0dB)
            let normalized = max(0.0, min(1.0, (db + 60.0) / 60.0))
            
            DispatchQueue.main.async {
                // Ballistic decay: rise instantly, fall smoothly
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
        
        // Fire immediately on start
        pollTelemetry()
        
        // Use .common mode so the timer fires even when MenuBarExtra panel is open
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
        
        // Real combined I/O latency
        let inputLatency = engine.inputNode.presentationLatency
        let outputLatency = engine.outputNode.presentationLatency
        let combinedLatency = inputLatency + outputLatency
        
        // Re-read stream specs (they can change after reconfiguration)
        let currentFormat = engine.inputNode.inputFormat(forBus: 0)
        let sr = currentFormat.sampleRate
        let ch = Int(currentFormat.channelCount)
        let fmt = formatName(for: currentFormat.commonFormat)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latency = combinedLatency
            if self.inputDeviceName != inDev { self.inputDeviceName = inDev }
            if self.outputDeviceName != outDev { self.outputDeviceName = outDev }
            if self.sampleRate != sr { self.sampleRate = sr }
            if self.channels != ch { self.channels = ch }
            if self.formatString != fmt { self.formatString = fmt }
            
            // Update uptime
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
