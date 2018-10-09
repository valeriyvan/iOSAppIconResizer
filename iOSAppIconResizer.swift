#!/usr/bin/swift

//  Created by Valeriy Van on 03-JUL-2018.
//  Copyright © 2018 Valeriy Van. All rights reserved.

import Foundation
import Cocoa

let sizes: [(Double, String)] = [
    // iPhone Notification
    // iOS 7-12
    // 20pt
    (40.0, "20@2x"),
    (60.0, "20@3x"),

    // iPhone
    // Settings - iOS 7-12
    // 29pt
    (29.0, "29"),
    (58.0, "29@2x"),
    (87.0, "29@3x"),

    // iPhone Spotlight
    // iOS 7-12
    // 40pt
    (80.0, "40@2x"),
    (120.0, "40@3x"),

    // iPhone App
    // iOS 5,6
    // 57pt
    (57.0, "57"),
    (114.0, "57@2x"),

    // iPhone App
    // iOS 7-12
    // 60pt
    (120.0, "60@2x"),
    (180.0, "60@3x"),

    // iPad Notifications
    // iOS 7-12
    // 20pt
    (20.0, "20"),
    (40.0, "20@2x"),

    // iPad Settings
    // iOS 7-12
    // 29pt
    (29.0, "29"),
    (58.0, "29@2x"),

    // iPad Spotlight
    // iOS 7-12
    // 40pt
    (40.0, "40"),
    (80.0, "40@2x"),

    // iPad Spotlight
    // iOS 5,6
    // 50pt
    (50.0, "50"),
    (100.0, "50@2x"),

    // iPad App
    // iOS 5,6
    // 72pt
    (72.0, "72"),
    (144.0, "72@2x"),

    // iPad App
    // iOS 7-12
    // 76pt
    (76.0, "76"),
    (152.0, "76@2x"),

    // iPad Pro App
    // iOS 9-12
    // 83.5pt
    (167.0, "83,5@2x"),

    // App Store
    // iOS
    // 1024pt
    (1024.0, "1024")
]

extension NSImage {
    var unscaledBitmapImageRep: NSBitmapImageRep {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0 )
        else { preconditionFailure() }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    func write(usingType type: NSBitmapImageRep.FileType, pixelsSize: NSSize?, to url: URL) throws {
        if let pixelsSize = pixelsSize {
            size = pixelsSize
        }
        guard let data = unscaledBitmapImageRep.representation(using: type, properties: [.compressionFactor: 1.0]) else {
            preconditionFailure()
        }
        try data.write(to: url)
    }
}

func main() -> Int32 {
    let defaultOutputFolder = "output"
    let defaultExt = "png"

    guard [2,3].contains(CommandLine.argc) else {
        let url = URL(fileURLWithPath: CommandLine.arguments[0])
        let name = url.lastPathComponent
        print("""
            Usage: \(name) path-to-source-icon [output-folder]
                Rescales source icon to sizes needed by Xcode 10 for iOS 7 - 12 and puts them to output-folder.
                If output-folder is not provided, subfolder `\(defaultOutputFolder)` of path-to-source-icon is used.
            """)
        return 1
    }

    let inputUrl = URL(fileURLWithPath: CommandLine.arguments[1])
    let inputName = inputUrl.deletingPathExtension().lastPathComponent
    let ext = inputUrl.pathExtension.isEmpty ? defaultExt : inputUrl.pathExtension
    guard let inputImage = NSImage(contentsOf: inputUrl) else {
        print("Can't open \(inputUrl)")
        return -1
    }

    let outputFolderUrl = CommandLine.argc == 3 ?
        URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true) :
        inputUrl.deletingLastPathComponent().appendingPathComponent(defaultOutputFolder, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: outputFolderUrl, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print(error)
        // continue
    }

    for (size, suffix) in sizes {
        let outputUrl = outputFolderUrl
            .appendingPathComponent(inputName + suffix, isDirectory: false)
            .appendingPathExtension(ext)
        print(outputUrl.path.removingPercentEncoding ?? outputUrl.path, terminator: "")
        do {
            try inputImage.write(usingType: .png, pixelsSize: NSSize(width: size, height: size), to: outputUrl)
        } catch {
            print(" ", error)
            continue
        }
        print()
    }

    return 0
}

let code = main()
exit(code)
