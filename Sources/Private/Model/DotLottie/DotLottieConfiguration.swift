//
// DotLottieSettings.swift
// Lottie
//
// Created by Evandro Hoffmann on 19/10/22.
//

import Foundation
#if !os(watchOS)
struct DotLottieConfiguration {
  var id: String
  var imageProvider: AnimationImageProvider?
  var loopMode: LottieLoopMode
  var speed: Double
}
#endif
