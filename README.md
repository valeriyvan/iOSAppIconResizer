CLI for resizing icons for iOS app in command line.

Usage: `iOSAppIconResizer.swift path-to-source-icon [output]`

Rescales source icon to sizes needed by Xcode 11 for iOS 7 - 14 and puts them to output-folder.
If output is not provided, subfolder `output` in path-to-source-icon is used for writing images, 
filename of path-to-source-icon is used as base of file name.
If output is provided, it might specify output folder, base file name or both:
* if output doesn't contain `/` it is treated as base file name only;
* if output ends with `/` it is treated as specifying output folder only;
* otherwise part before last `/` is treated as output folder and after last `/` as base file name.
