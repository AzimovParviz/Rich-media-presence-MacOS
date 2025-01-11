import AppKit
import Combine

struct NowPlayingInfo {
    var songTitle: String
    var artistName: String
    var albumArt: NSImage
    var songDuration: TimeInterval
}

func nowPlayingInfo(completion: @escaping (String) -> Void) {
    let mediaRemoteBundle: CFBundle
    let MRMediaRemoteGetNowPlayingInfo:
        @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    let MRMediaRemoteGetNowPlayingApplicationIsPlaying:
        @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    let MRMediaRemoteGetNowPlayingClient:
        @convention(c) (DispatchQueue, @escaping (Any) -> Void) -> Void
    let MRNowPlayingClientGetBundleIdentifier:
        @convention(c) ([String: Any]) -> String
    let MRNowPlayingClientGetParentAppBundleIdentifier:
        @convention(c) ([String: Any]) -> String

    guard
        let bundle = CFBundleCreate(
            kCFAllocatorDefault,
            NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
        let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(
            bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString),
        let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer =
            CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString),
        let MRMediaRemoteGetNowPlayingClientPointer =
            CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteGetNowPlayingClient" as CFString),
        let MRNowPlayingClientGetBundleIdentifierPointer =
            CFBundleGetFunctionPointerForName(
                bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString),
        let MRNowPlayingClientGetParentAppBundleIdentifierPointer =
            CFBundleGetFunctionPointerForName(
                bundle, "MRNowPlayingClientGetParentAppBundleIdentifier" as CFString)
    else {
        print("Failed to load MediaRemote.framework or get function pointers")
        // throw NSError(domain: "com.example.nowPlayingInfo", code: 1)
        completion("failed")
        return
    }

    mediaRemoteBundle = bundle
    // the original func is MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {});
    MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(
        MRMediaRemoteGetNowPlayingInfoPointer,
        to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
    MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(
        MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer,
        to: (@convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void).self)
    MRMediaRemoteGetNowPlayingClient = unsafeBitCast(
        MRMediaRemoteGetNowPlayingClientPointer,
        to: (@convention(c) (DispatchQueue, @escaping (Any) -> Void) -> Void).self)
    MRNowPlayingClientGetBundleIdentifier = unsafeBitCast(
        MRNowPlayingClientGetBundleIdentifierPointer,
        to: (@convention(c) ([String: Any]) -> String).self)
    MRNowPlayingClientGetParentAppBundleIdentifier = unsafeBitCast(
        MRNowPlayingClientGetParentAppBundleIdentifierPointer,
        to: (@convention(c) ([String: Any]) -> String).self)

    var nowPlayingInfo = NowPlayingInfo(
        songTitle: "",
        artistName: "",
        albumArt: NSImage(),
        songDuration: 0
    )
    print("Calling MRMediaRemoteGetNowPlayingInfo")
    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.global(qos: .default)) { information in

        // print(information["kMRMediaRemoteNowPlayingInfoClientPropertiesData"] as? NSData ?? nil)
        nowPlayingInfo.songTitle =
            information["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? "Unknown Title"
        nowPlayingInfo.artistName =
            information["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? "Unknown Artist"
        nowPlayingInfo.songDuration =
            information["kMRMediaRemoteNowPlayingInfoDuration"] as? TimeInterval ?? 0

        if let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data,
            let artworkImage = NSImage(data: artworkData)
        {
            nowPlayingInfo.albumArt = artworkImage
            print("Album art successfully retrieved.")
        } else {
            print("No album art available.")
        }

        let result =
            "Title: \(nowPlayingInfo.songTitle)\nArtist: \(nowPlayingInfo.artistName)\nDuration: \(nowPlayingInfo.songDuration)\nArtwork: \(String(describing: information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data))"
        print("printed result", result)
        do {
            //TODO: temporary file instead of project folder
            let fileURL = URL(fileURLWithPath: "/tmp/song.txt")
            try result.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Now playing info written to song.txt")
        } catch {
            print("Failed to write to song.txt: \(error)")
        }

        MRMediaRemoteGetNowPlayingClient(DispatchQueue.global(qos: .default)) { clientObj in
            // print("Client info", clientObj)
            let clientString = String(describing: clientObj)
            print("Client info", clientString)
            let fileURL = URL(fileURLWithPath: "/tmp/client.txt")
            do {
                try clientString.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Client info written to client.txt")
            } catch {
                print("Failed to write client info to file: \(error)")
            }
            // print("Bundle ID", MRNowPlayingClientGetBundleIdentifier(clientObj as! [String: Any])) 
            completion("success")
        }

        if let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {

            //TODO: use kMRMediaRemoteNowPlayingInfoArtworkMIMEType for this
            let artworkURL = URL(fileURLWithPath: "/tmp/albumArt.jpeg")
            do {
                try artworkData.write(to: artworkURL)
                print("Album art written to albumArt.jpeg")
            } catch {
                print("Failed to write album art to albumArt.jpeg: \(error)")
            }
        }
        CFRunLoopStop(CFRunLoopGetCurrent())
        print("after return somehow")
        return
    }
    return
}

@_cdecl("returnNowPlayingInfo")
public func returnNowPlayingInfo() {
    nowPlayingInfo { result in
        print("result", result)
    }
}

