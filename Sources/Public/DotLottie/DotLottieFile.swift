//
// DotLottie.swift
// Lottie
//
// Created by Evandro Harrison Hoffmann on 27/06/2020.
//
#if !os(watchOS)
import Foundation

// MARK: - DotLottieFile

/// Detailed .lottie file structure
public final class DotLottieFile {

  // MARK: Lifecycle

  /// Loads `DotLottie` from `Data` object containing a compressed animation.
  ///
  /// - Parameters:
  ///  - data: Data of .lottie file
  ///  - filename: Name of .lottie file
  ///  - Returns: Deserialized `DotLottie`. Optional.
  init(data: Data, filename: String) throws {
    fileUrl = DotLottieUtils.tempDirectoryURL.appendingPathComponent(filename.asFilename())
    try decompress(data: data, to: fileUrl)
  }

  // MARK: Internal

  /// Definition for a single animation within a `DotLottieFile`
  struct Animation {
    let animation: LottieAnimation
    let configuration: DotLottieConfiguration
  }

  /// List of `LottieAnimation` in the file
  private(set) var animations: [Animation] = []

  /// Image provider for animations
  private(set) var imageProvider: AnimationImageProvider?

  /// Manifest.json file loading
  lazy var manifest: DotLottieManifest? = {
    let path = fileUrl.appendingPathComponent(DotLottieFile.manifestFileName)
    return try? DotLottieManifest.load(from: path)
  }()

  /// Animation url for main animation
  lazy var animationUrl: URL? = {
    guard let animationId = manifest?.animations.first?.id else { return nil }
    let dotLottieJson = "\(DotLottieFile.animationsFolderName)/\(animationId).json"
    return fileUrl.appendingPathComponent(dotLottieJson)
  }()

  /// Animations folder url
  lazy var animationsUrl: URL = fileUrl.appendingPathComponent("\(DotLottieFile.animationsFolderName)")

  /// All files in animations folder
  lazy var animationUrls: [URL] = {
    FileManager.default.urls(for: animationsUrl) ?? []
  }()

  /// Images folder url
  lazy var imagesUrl: URL = fileUrl.appendingPathComponent("\(DotLottieFile.imagesFolderName)")

  /// All images in images folder
  lazy var imageUrls: [URL] = {
    FileManager.default.urls(for: imagesUrl) ?? []
  }()

  /// The `LottieAnimation` and `DotLottieConfiguration` for the given animation ID in this file
  func animation(for id: String? = nil) -> DotLottieFile.Animation? {
    if let id = id {
      return animations.first(where: { $0.configuration.id == id })
    } else {
      return animations.first
    }
  }

  // MARK: Private

  private static let manifestFileName = "manifest.json"
  private static let animationsFolderName = "animations"
  private static let imagesFolderName = "images"

  private let fileUrl: URL

  private var dotLottieAnimations: [DotLottieAnimation] {
    manifest?.animations.map {
      var animation = $0
      animation.animationUrl = animationsUrl.appendingPathComponent("\($0.id).json")
      return animation
    } ?? []
  }

  /// Decompresses .lottie file from `URL` and saves to local temp folder
  ///
  /// - Parameters:
  ///  - url: url to .lottie file
  ///  - destinationURL: url to destination of decompression contents
  private func decompress(from url: URL, to destinationURL: URL) throws {
    try? FileManager.default.removeItem(at: destinationURL)
    try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
    try FileManager.default.unzipItem(at: url, to: destinationURL)
    loadContent()
    try? FileManager.default.removeItem(at: destinationURL)
    try? FileManager.default.removeItem(at: url)
  }

  /// Decompresses .lottie file from `Data` and saves to local temp folder
  ///
  /// - Parameters:
  ///  - url: url to .lottie file
  ///  - destinationURL: url to destination of decompression contents
  private func decompress(data: Data, to destinationURL: URL) throws {
    let url = destinationURL.appendingPathExtension("lottie")
    try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
    try data.write(to: url)
    try decompress(from: url, to: destinationURL)
  }

  /// Loads file content to memory
  private func loadContent() {
    imageProvider = DotLottieImageProvider(filepath: imagesUrl)

    animations = dotLottieAnimations.compactMap { dotLottieAnimation -> DotLottieFile.Animation? in
      guard let animation = try? dotLottieAnimation.animation() else {
        return nil
      }

      let configuration = DotLottieConfiguration(
        id: dotLottieAnimation.id,
        imageProvider: imageProvider,
        loopMode: dotLottieAnimation.loopMode,
        speed: dotLottieAnimation.animationSpeed)

      return DotLottieFile.Animation(
        animation: animation,
        configuration: configuration)
    }
  }
}

extension String {

  // MARK: Fileprivate

  fileprivate func asFilename() -> String {
    lastPathComponent().removingPathExtension()
  }

  // MARK: Private

  private func lastPathComponent() -> String {
    (self as NSString).lastPathComponent
  }

  private func removingPathExtension() -> String {
    (self as NSString).deletingPathExtension
  }
}
#endif
