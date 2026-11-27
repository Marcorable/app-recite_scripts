import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var toolbarController: DuoToolbarNavigationController?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard
      let flutterViewController = window?.rootViewController as? FlutterViewController
    else { return }

    let controller = DuoToolbarNavigationController(
      flutterViewController: flutterViewController
    )
    toolbarController = controller
    window?.rootViewController = controller
  }
}

private final class DuoToolbarNavigationController: UINavigationController {
  private static let channelName = "com.marcorable.maltto/duo_toolbar"

  private let flutterViewController: FlutterViewController
  private lazy var addItem: UIBarButtonItem = {
    let item = UIBarButtonItem(
      systemItem: .add,
      primaryAction: UIAction { [weak self] _ in
        self?.channel.invokeMethod("openCreate", arguments: nil)
      }
    )
    item.accessibilityLabel = "새 대본 추가"
    return item
  }()
  private lazy var addGroup = UIBarButtonItemGroup.fixedGroup(items: [addItem])
  private lazy var channel = FlutterMethodChannel(
    name: Self.channelName,
    binaryMessenger: flutterViewController.binaryMessenger
  )

  init(flutterViewController: FlutterViewController) {
    self.flutterViewController = flutterViewController
    super.init(rootViewController: flutterViewController)
    navigationBar.prefersLargeTitles = false
    flutterViewController.navigationItem.pinnedTrailingGroup = addGroup
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "isVerticalToolbar":
        result(self.usesVerticalToolbar)
      case "setAddVisible":
        self.addGroup.isHidden = !((call.arguments as? Bool) ?? true)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updateToolbarPlacement()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateToolbarPlacement()
  }

  private var usesVerticalToolbar: Bool {
    guard #available(iOS 27.1, *) else { return false }
    return traitCollection.verticalBarEdge != .unspecified
  }

  private func updateToolbarPlacement() {
    let isVertical = usesVerticalToolbar
    setNavigationBarHidden(!isVertical, animated: false)
    channel.invokeMethod("verticalToolbarChanged", arguments: isVertical)
  }

}
