//
//  ContentView.swift
//  lemonra1n
//
//  Created by Hornbeck on 9/21/22.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State var SelectBlob = false
    @State var Blob = ""
    @State var iOS = ""
    @State var IsJailbreaking = false
    @State var JailbreakStep = ""
    @State var JailbreakProgress: Double = 1
    @Environment(\.openURL) var openURL
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        SelectBlob.toggle()
                    } label: {
                        Text(Blob.isEmpty ? "Select Blob" : "Change Blob")
                    }
                    TextField("  iOS", text: $iOS)
                        .frame(width: 50)
                }
                Button {
                    DispatchQueue.global(qos: .utility).async {
                        Jailbreak(Blob: Blob, iOS: iOS)
                    }
                } label: {
                    Text("Jailbreak")
                }
                .disabled(IsJailbreaking ? !JailbreakStep.contains("Jailbroken") : Blob.isEmpty || iOS.isEmpty)
                if IsJailbreaking {
                    VStack {
                        Text("[*] \(JailbreakStep)")
                        ProgressView(value: JailbreakProgress, total: 100)
                            .frame(width: 350, height: 1)
                    }
                }
                HStack {
                    Text("Made by")
                    Button {
                        openURL(URL(string: "https://twitter.com/AppInstalleriOS")!)
                    } label: {
                        Text("@AppInstalleriOS")
                    }
                }
                .offset(y: IsJailbreaking ? 65 : 80)
            }
        }
        .frame(width: 450, height: 250)
        .fileImporter(isPresented: $SelectBlob, allowedContentTypes: [UTType(filenameExtension: "shsh")!, UTType(filenameExtension: "shsh2")!]) { result in
            do {
                Blob = try result.get().path.replacingOccurrences(of: " ", with: "\\ ")
            } catch {
                print("Error")
            }
        }
        .onAppear {
            let AppDataDirectory = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "")
            if !FileManager.default.fileExists(atPath: "\(AppDataDirectory)/lemonra1n-boot") {
                do {
                    try FileManager.default.createDirectory(atPath: "\(AppDataDirectory)/lemonra1n-boot", withIntermediateDirectories: false)
                } catch {
                    print("Error Making lemonra1n-boot Directory")
                }
            }
        }
    }
    func Jailbreak(Blob: String, iOS: String) {
        IsJailbreaking = true
        var JailbreakSteps = "3"
        var CurrentJailbreakStep = "1"
        let AppDataDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
        let dir = "\(AppDataDirectory)/lemonra1n-boot"
        let bindir = "\(Bundle.main.bundlePath)/Contents/Resources"
        let out = "/dev/null"
        shell("chmod +x \(bindir)/*")
        JailbreakStep = "Getting device info... (\(CurrentJailbreakStep)/\(JailbreakSteps))"
        let cpid = shellWithReturn("\(bindir)/irecovery -q | grep CPID | sed 's/CPID: //'")
        let deviceid = shellWithReturn("\(bindir)/irecovery -q | grep PRODUCT | sed 's/PRODUCT: //'")
        let model = shellWithReturn("\(bindir)/irecovery -q | grep MODEL | sed 's/MODEL: //'")
        let ipswurl = shellWithReturn("curl -sL \"https://api.ipsw.me/v4/device/\(deviceid)?type=ipsw\" | \(bindir)/jq '.firmwares | .[] | select(.version==\"'\(iOS)'\") | .url' --raw-output")
        let modelname = shellWithReturn("\(bindir)/irecovery -q | grep NAME | sed 's/NAME: //'")
        if !FileManager.default.fileExists(atPath: "\(dir)/boot-\(deviceid)") {
            if FileManager.default.fileExists(atPath: "\(dir)/work") {
                shell("cd \(dir) && rm -rf work")
            } else {
                shell("cd \(dir) && mkdir work")
            }
            JailbreakSteps = "14"
            CurrentJailbreakStep = "2"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Pwning device (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("\(bindir)/gaster pwn > \(out)")
            shell("cd \(dir) && mkdir boot-\(deviceid)")
            CurrentJailbreakStep = "3"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Downloading BuildManifest (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/pzb -g BuildManifest.plist \(ipswurl) > \(out)")
            shell("cd \(dir)/work && \(bindir)/img4tool -e -s \(Blob) -m IM4M > \(out)")
            CurrentJailbreakStep = "4"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Downloading and decrypting iBSS (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/pzb -g \(shellWithReturn("cd \(dir)/work && awk \"/\(cpid)/{x=1}x&&/iBSS[.]/{print;exit}\" BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1")) \(ipswurl) > \(out)")
            shell("cd \(dir)/work && \(bindir)/gaster decrypt \(shellWithReturn("cd \(dir)/work && awk \"/\(cpid)/{x=1}x&&/iBSS[.]/{print;exit}\" BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1 | sed 's/Firmware[/]dfu[/]//'")) iBSS.dec > \(out)")
            CurrentJailbreakStep = "5"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Downloading and decrypting iBEC (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/pzb -g \(shellWithReturn("cd \(dir)/work && awk \"/\(cpid)/{x=1}x&&/iBEC[.]/{print;exit}\" BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1")) \(ipswurl) > \(out)")
            shell("cd \(dir)/work && \(bindir)/gaster decrypt \(shellWithReturn("cd \(dir)/work && awk \"/\(cpid)/{x=1}x&&/iBEC[.]/{print;exit}\" BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1 | sed 's/Firmware[/]dfu[/]//'")) iBEC.dec > \(out)")
            CurrentJailbreakStep = "6"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Downloading DeviceTree (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/pzb -g Firmware/all_flash/DeviceTree.\(model).im4p \(ipswurl) > \(out)")
            CurrentJailbreakStep = "7"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Downloading trustcache (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/pzb -g \(shellWithReturn("cd \(dir)/work && /usr/bin/plutil -extract BuildIdentities.0.Manifest.StaticTrustCache.Info.Path xml1 -o - BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1 | head -1")) \(ipswurl) > \(out)")
            CurrentJailbreakStep = "8"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Downloading kernelcache (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/pzb -g \(shellWithReturn("cd \(dir)/work && awk \"/\(cpid)/{x=1}x&&/kernelcache.release/{print;exit}\" BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1")) \(ipswurl) > \(out)")
            CurrentJailbreakStep = "9"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Patching and repacking iBSS/iBEC (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir)/work && \(bindir)/iBoot64Patcher iBSS.dec iBSS.patched > \(out)")
            shell("cd \(dir)/work && \(bindir)/iBoot64Patcher iBEC.dec iBEC.patched -b '-v keepsyms=1 debug=0xfffffffe panic-wait-forever=1 wdt=-1' > \(out)")
            shell("cd \(dir) && \(bindir)/img4 -i work/iBSS.patched -o boot-\(deviceid)/iBSS.img4 -M work/IM4M -A -T ibss > \(out)")
            shell("cd \(dir) && \(bindir)/img4 -i work/iBEC.patched -o boot-\(deviceid)/iBEC.img4 -M work/IM4M -A -T ibec > \(out)")
            CurrentJailbreakStep = "10"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Patching and converting kernelcache (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            if deviceid.contains("iPhone8") {
                shell("cd \(dir) && python3 -m pyimg4 im4p extract -i work/\(shellWithReturn("cd \(dir) && awk \"/\(model)/{x=1}x&&/kernelcache.release/{print;exit}\" work/BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1")) -o work/kcache.raw --extra work/kpp.bin > \(out)")
            } else {
                shell("cd \(dir) && python3 -m pyimg4 im4p extract -i work/\(shellWithReturn("cd \(dir) && awk \"/\(model)/{x=1}x&&/kernelcache.release/{print;exit}\" work/BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1")) -o work/kcache.raw > \(out)")
            }
            shell("cd \(dir) && \(bindir)/Kernel64Patcher work/kcache.raw work/kcache.patched -a -o > \(out)")
            if deviceid.contains("iPhone8") {
                shell("cd \(dir) && python3 -m pyimg4 im4p create -i work/kcache.patched -o work/krnlboot.im4p --extra work/kpp.bin -f rkrn --lzss > \(out)")
            } else {
                shell("cd \(dir) && python3 -m pyimg4 im4p create -i work/kcache.patched -o work/krnlboot.im4p -f rkrn --lzss > \(out)")
            }
            shell("cd \(dir) && python3 -m pyimg4 img4 create -p work/krnlboot.im4p -o boot-\(deviceid)/kernelcache.img4 -m work/IM4M > \(out)")
            CurrentJailbreakStep = "11"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Converting DeviceTree (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir) && \(bindir)/img4 -i work/\(shellWithReturn("cd \(dir) && awk \"/\(model)/{x=1}x&&/DeviceTree[.]/{print;exit}\" work/BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1 | sed 's/Firmware[/]all_flash[/]//'")) -o boot-\(deviceid)/devicetree.img4 -M work/IM4M -T rdtr > \(out)")
            CurrentJailbreakStep = "12"
            JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
            JailbreakStep = "Patching and converting trustcache (\(CurrentJailbreakStep)/\(JailbreakSteps))"
            shell("cd \(dir) && \(bindir)/img4 -i work/\(shellWithReturn("cd \(dir) && /usr/bin/plutil -extract BuildIdentities.0.Manifest.StaticTrustCache.Info.Path xml1 -o - work/BuildManifest.plist | grep '<string>' | cut -d\\> -f2 | cut -d\\< -f1 | head -1 | sed 's/Firmware\\///'")) -o boot-\(deviceid)/trustcache.img4 -M work/IM4M -T rtsc > \(out)")
            if FileManager.default.fileExists(atPath: "\(dir)/work") {
                shell("cd \(dir) && rm -rf work")
            }
        }
        CurrentJailbreakStep = JailbreakSteps == "3" ? "2" : "13"
        JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
        JailbreakStep = "Pwning device (\(CurrentJailbreakStep)/\(JailbreakSteps))"
        shell("\(bindir)/gaster pwn > \(out)")
        shell("\(bindir)/gaster reset > \(out)")
        CurrentJailbreakStep = JailbreakSteps == "3" ? "3" : "14"
        JailbreakProgress = FractionToDouble(CurrentJailbreakStep, JailbreakSteps)
        JailbreakStep = "Booting device (\(CurrentJailbreakStep)/\(JailbreakSteps))"
        shell("cd \(dir) && \(bindir)/irecovery -f boot-\(deviceid)/iBSS.img4")
        shell("cd \(dir) && \(bindir)/irecovery -f boot-\(deviceid)/iBEC.img4")
        if cpid == "0x80" {
            shell("\(bindir)/irecovery -c go")
        }
        shell("cd \(dir) && \(bindir)/irecovery -f boot-\(deviceid)/devicetree.img4")
        shell("cd \(dir) && \(bindir)/irecovery -c devicetree")
        shell("cd \(dir) && \(bindir)/irecovery -f boot-\(deviceid)/trustcache.img4")
        shell("cd \(dir) && \(bindir)/irecovery -c firmware")
        shell("cd \(dir) && \(bindir)/irecovery -f boot-\(deviceid)/kernelcache.img4")
        shell("cd \(dir) && \(bindir)/irecovery -c bootx")
        JailbreakStep = "Your \(modelname) Is Jailbroken!"
        shell("defaults write -g ignore-devices -bool false")
        shell("defaults write com.apple.AMPDevicesAgent dontAutomaticallySyncIPods -bool false")
    }
}

func shellWithReturn(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    return String(output.dropLast())
}

func shell(_ command: String) {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
}

func FractionToDouble(_ CurrentJailbreakStep: String, _ JailbreakSteps: String) -> Double {
    return Double((Int(CurrentJailbreakStep)! * 100)/Int(JailbreakSteps)!)
}
