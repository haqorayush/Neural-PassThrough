import AVFoundation
import AudioToolbox

var desc = AudioComponentDescription(
    componentType: kAudioUnitType_Effect,
    componentSubType: kAudioUnitSubType_DynamicsProcessor,
    componentManufacturer: kAudioUnitManufacturer_Apple,
    componentFlags: 0,
    componentFlagsMask: 0
)
let compressor = AVAudioUnitEffect(audioComponentDescription: desc)
print("Success")
