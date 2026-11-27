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

private final class DuoToolbarNavigationController: UINavigationController, DuoToolbarHostApi {
  private let flutterViewController: FlutterViewController
  private let flutterApi: DuoToolbarFlutterApi
  private lazy var addItem: UIBarButtonItem = {
    let item = UIBarButtonItem(
      systemItem: .add,
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        Task { try await self.flutterApi.openCreate() }
      }
    )
    item.accessibilityLabel = "새 대본 추가"
    return item
  }()
  private lazy var addGroup = UIBarButtonItemGroup.fixedGroup(items: [addItem])

  init(flutterViewController: FlutterViewController) {
    self.flutterViewController = flutterViewController
    self.flutterApi = DuoToolbarFlutterApi(
      binaryMessenger: flutterViewController.binaryMessenger
    )
    super.init(rootViewController: flutterViewController)
    navigationBar.prefersLargeTitles = false
    flutterViewController.navigationItem.pinnedTrailingGroup = addGroup
    DuoToolbarHostApiSetup.setUp(
      binaryMessenger: flutterViewController.binaryMessenger,
      api: self
    )
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

  func isVerticalToolbar() throws -> Bool {
    usesVerticalToolbar
  }

  func setAddVisible(visible: Bool) throws {
    addGroup.isHidden = !visible
  }

  private func updateToolbarPlacement() {
    let isVertical = usesVerticalToolbar
    setNavigationBarHidden(!isVertical, animated: false)
    Task { try await flutterApi.verticalToolbarChanged(isVertical: isVertical) }
  }

}
