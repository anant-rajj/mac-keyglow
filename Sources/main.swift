//
//  main.swift
//  KeyGlow
//
//  Main entrypoint for KeyGlow.
//  Dispatches to CLI command handler if arguments were passed,
//  otherwise launches the native Menu Bar status app.
//

import Cocoa

if CLIHandler.handleArguments(CommandLine.arguments) {
    exit(0)
}

let app = NSApplication.shared
let controller = MenuController()
app.delegate = controller
app.setActivationPolicy(.accessory)
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
