#!/usr/bin/swift

//  iOSAppIconResizer
//  Created by Valeriy Van on 03-JUL-2018.
//  Copyright © 2018 Valeriy Van. All rights reserved.

import Foundation
import Cocoa

let sizes: [(NSSize, String)] = [
    // iPhone Notification
    // iOS 7-11
    // 20pt
    (NSSize(width: 40, height: 40), "20@2x"),
    (NSSize(width: 60, height: 60), "20@3x"),

    // iPhone
    // Spotlight - iOS 5,6
    // Settings - iOS 5-11
    (NSSize(width: 58, height: 58), "29@2x"),
    (NSSize(width: 87, height: 87), "29@3x"),

    // iPhone Spotlight
    // iOS 7-11
    // 40pt
    (NSSize(width: 80, height: 80), "40@2x"),
    (NSSize(width: 120, height: 120), "40@3x"),

    // iPhone App
    // iOS 7-11
    // 60pt
    (NSSize(width: 120, height: 120), "60@2x"),
    (NSSize(width: 180, height: 180), "60@3x"),

    // iPad Notifications
    // iOS 7-11
    // 20pt
    (NSSize(width: 20, height: 20), "20"),
    (NSSize(width: 40, height: 40), "20@2x"),

    // iPad Settings iOS 5-11 29pt
    (NSSize(width: 29, height: 29), "29"),
    (NSSize(width: 58, height: 58), "29@2x"),

    // iPad Spotlight
    // iOS 7-11
    // 40pt
    (NSSize(width: 40, height: 40), "40"),
    (NSSize(width: 80, height: 80), "40@2x"),

    // iPad App
    // iOS 7-11
    // 76pt
    (NSSize(width: 76, height: 76), "76"),
    (NSSize(width: 152, height: 152), "76@2x"),

    // iPad Pro App
    // iOS 9-11
    // 83.5pt
    (NSSize(width: 167, height: 167), "83,5@2x"),

    // App Store iOS
    // 1024pt
    (NSSize(width: 1024, height: 1024), "1024")
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
}

func main() -> Int32 {
    let defaultOutputFolder = "output"
    let defaultExt = "png"

    guard [2,3].contains(CommandLine.argc) else {
        let url = URL(fileURLWithPath: CommandLine.arguments[0])
        let name = url.lastPathComponent
        print("Usage: \(name) path-to-source-icon [output-folder]")
        print("Rescales source icon to sizes needed by iOS 7 - 11 and puts them to output-folder.")
        print("If output-folder is not provided, subfolder `\(defaultOutputFolder)` of path-to-source-icon is used.")
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
        let newSize = NSSize(width: size.width / 2.0, height: size.height / 2.0) // TODO: !!!
        let outputUrl = outputFolderUrl.appendingPathComponent(inputName + suffix, isDirectory: false).appendingPathExtension(ext)

        print(outputUrl.path.removingPercentEncoding ?? outputUrl.path)

        let resized = inputImage.resized(to: newSize)!

        resized.lockFocus()
        let bitmapRep = NSBitmapImageRep(focusedViewRect: NSRect(origin: .zero, size: newSize))!
        resized.unlockFocus()

        let pngData = bitmapRep.representation(using: .png, properties: [:])!
        do {
            try pngData.write(to: outputUrl)
        } catch let error {
            print(error)
        }
    }
    print("done")
    return 0
}

exit(main())
