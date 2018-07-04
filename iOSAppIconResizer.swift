#!/usr/bin/swift

//  Created by Valeriy Van on 03-JUL-2018.
//  Copyright © 2018 Valeriy Van. All rights reserved.

import Foundation
import Cocoa

let sizes: [(Double, String)] = [
    // iPhone Notification
    // iOS 7-11
    // 20pt
    (40.0, "20@2x"),
    (60.0, "20@3x"),

    // iPhone
    // Spotlight - iOS 5,6
    // Settings - iOS 5-11
    (58.0, "29@2x"),
    (87.0, "29@3x"),

    // iPhone Spotlight
    // iOS 7-11
    // 40pt
    (80.0, "40@2x"),
    (120.0, "40@3x"),

    // iPhone App
    // iOS 7-11
    // 60pt
    (120.0, "60@2x"),
    (180.0, "60@3x"),

    // iPad Notifications
    // iOS 7-11
    // 20pt
    (20.0, "20"),
    (40.0, "20@2x"),

    // iPad Settings
    // iOS 5-11
    // 29pt
    (29.0, "29"),
    (58.0, "29@2x"),

    // iPad Spotlight
    // iOS 7-11
    // 40pt
    (40.0, "40"),
    (80.0, "40@2x"),

    // iPad App
    // iOS 7-11
    // 76pt
    (76.0, "76"),
    (152.0, "76@2x"),

    // iPad Pro App
    // iOS 9-11
    // 83.5pt
    (167.0, "83,5@2x"),

    // App Store iOS
    // 1024pt
    (1024.0, "1024")
]

extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)
            else { return nil }
        bitmapRep.size = newSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        let resizedImage = NSImage(size: newSize)
        resizedImage.addRepresentation(bitmapRep)
        return resizedImage
    }

    var png: Data? {
        lockFocus()
        defer { unlockFocus() }
        guard let bitmap = NSBitmapImageRep(focusedViewRect: NSRect(origin: .zero, size: size)) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
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
                Rescales source icon to sizes needed by iOS 7 - 11 and puts them to output-folder.
                If output-folder is not provided, subfolder `\(defaultOutputFolder)` of path-to-source-icon is used.
            """)
        return 1
    }

    let inputUrl = URL(fileURLWithPath: CommandLine.arguments[1])
    let inputName = inputUrl.deletingPathExtension().lastPathComponent
    var ext = inputUrl.pathExtension
    if ext.isEmpty {
        ext = defaultExt
    }
    guard let inputImage = NSImage(contentsOf: inputUrl) else {
        print("Can't open \(inputUrl)")
        return -1
    }

    let outputFolderUrl = CommandLine.argc == 3 ? URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true) : inputUrl.deletingLastPathComponent().appendingPathComponent(defaultOutputFolder, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: outputFolderUrl, withIntermediateDirectories: true, attributes: nil)
    } catch {
        print(error)
        // continue
    }

    for (size, suffix) in sizes {
        let newSize = NSSize(width: size / 2.0, height: size / 2.0) // TODO: !!!
        let outputUrl = outputFolderUrl
            .appendingPathComponent(inputName + suffix, isDirectory: false)
            .appendingPathExtension(ext)
        print(outputUrl.path.removingPercentEncoding ?? outputUrl.path, terminator: "")
        guard let png = inputImage.resized(to: newSize)?.png else {
            print(" rescaling failed")
            continue
        }
        do {
            try png.write(to: outputUrl)
        } catch {
            print(" ", error)
            continue
        }
        print()
    }

    return 0
}

exit(main())
