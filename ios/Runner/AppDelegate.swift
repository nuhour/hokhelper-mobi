import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var mediaChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "HokHelperMediaPlugin"
      )
    else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "hokhelper/media",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "saveImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.saveImage(call: call, result: result)
    }
    mediaChannel = channel
  }

  private func saveImage(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["bytes"] as? FlutterStandardTypedData,
      !typedData.data.isEmpty
    else {
      result(false)
      return
    }

    let fileName = (arguments["name"] as? String)?.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    requestPhotoAddAuthorization { status in
      let isAuthorized: Bool
      if #available(iOS 14, *) {
        isAuthorized = status == .authorized || status == .limited
      } else {
        isAuthorized = status == .authorized
      }
      guard isAuthorized else {
        DispatchQueue.main.async { result(false) }
        return
      }

      PHPhotoLibrary.shared().performChanges {
        let request = PHAssetCreationRequest.forAsset()
        let options = PHAssetResourceCreationOptions()
        if let fileName, !fileName.isEmpty {
          options.originalFilename = fileName
        }
        request.addResource(
          with: .photo,
          data: typedData.data,
          options: options
        )
      } completionHandler: { success, _ in
        DispatchQueue.main.async { result(success) }
      }
    }
  }

  private func requestPhotoAddAuthorization(
    completion: @escaping (PHAuthorizationStatus) -> Void
  ) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: completion)
    } else {
      PHPhotoLibrary.requestAuthorization(completion)
    }
  }
}
