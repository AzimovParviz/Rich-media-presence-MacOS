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

    guard
        let bundle = CFBundleCreate(
            kCFAllocatorDefault,
            NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")),
        let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(
            bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString),
        let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer =
            CFBundleGetFunctionPointerForName(
                bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString)
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
    var nowPlayingInfo = NowPlayingInfo(
        songTitle: "",
        artistName: "",
        albumArt: NSImage(),
        songDuration: 0
    )
    print("Calling MRMediaRemoteGetNowPlayingInfo")
    MRMediaRemoteGetNowPlayingInfo(DispatchQueue.global(qos: .default)) { information in

        print("Hello")
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
            let fileURL = URL(fileURLWithPath: "/Users/kitten/projects/go-rpc/song.txt")
            try result.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Now playing info written to song.txt")
        } catch {
            print("Failed to write to song.txt: \(error)")
        }
        if let artworkData = information["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {

            let artworkURL = URL(fileURLWithPath: "/Users/kitten/projects/go-rpc/albumArt.jpeg")
            do {
            try artworkData.write(to: artworkURL)
            print("Album art written to albumArt.jpeg")
            } catch {
            print("Failed to write album art to albumArt.jpeg: \(error)")
            }
        }   
            CFRunLoopStop(CFRunLoopGetCurrent())
            print("after return somehow");
            return 
    }
    return
}

@_cdecl("returnNowPlayingInfo")
public func returnNowPlayingInfo() -> Void {
    nowPlayingInfo { result in
        print("result", result)
    }
}
