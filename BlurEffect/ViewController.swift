import UIKit

final class ViewController: UIViewController {
	private var label: UILabel!
	private var visualEffectView: ContentVisualEffectView!
	private var animator: UIViewPropertyAnimator?

	override func loadView() {
		super.loadView()
		view.backgroundColor = .systemBackground

		visualEffectView = ContentVisualEffectView()
		label = UILabel()
		label.text = "🔮"
		label.font = .systemFont(ofSize: 200)

		let animateInButton = UIButton(
			configuration: .borderedTinted(),
			primaryAction: UIAction(title: "Animate In") { [weak self] _ in
				guard let self else { return }
				updateLabel(visible: true, animated: true)
			},
		)

		let animateOutButton = UIButton(
			configuration: .borderedTinted(),
			primaryAction: UIAction(title: "Animate Out") { [weak self] _ in
				guard let self else { return }
				updateLabel(visible: false, animated: true)
			},
		)

		let slider = UISlider(frame: .zero, primaryAction: UIAction { [weak self] action in
			guard let self else { return }
			animator?.pauseAnimation()
			animator?.fractionComplete = CGFloat((action.sender as! UISlider).value)
		})

		let controlsStackView = UIStackView(arrangedSubviews: [animateInButton, animateOutButton, slider])
		controlsStackView.spacing = 10

		label.translatesAutoresizingMaskIntoConstraints = false
		visualEffectView.contentView.addSubview(label)

		visualEffectView.translatesAutoresizingMaskIntoConstraints = false
		controlsStackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(visualEffectView)
		view.addSubview(controlsStackView)

		NSLayoutConstraint.activate([
			visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
			visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

			label.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
			label.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),

			controlsStackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			controlsStackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			controlsStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20),
		])
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		updateLabel(visible: false, animated: false)
	}

	private func updateLabel(visible: Bool, animated: Bool) {
		func updateViews() {
			if visible {
				visualEffectView.effect = nil
				label.alpha = 1
				label.transform = .identity
			} else {
				visualEffectView.effect = UIBlurEffect.effect(withBlurRadius: 30)
				label.alpha = 0
				label.transform = CGAffineTransform(scaleX: 2, y: 2)
			}
		}

		guard animated else {
			updateViews()
			return
		}

		animator?.stopAnimation(true)
		let timingParameters = UISpringTimingParameters(duration: 0.5, bounce: 0.2)
		animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
		animator?.addAnimations(updateViews)
		animator?.startAnimation()
	}
}

private final class ContentVisualEffectView: UIVisualEffectView {
	override var effect: UIVisualEffect? {
		get {
			guard responds(to: NSSelectorFromString("contentEffects")) else { return nil }
			let contentEffects = value(forKey: "contentEffects") as? [UIVisualEffect]
			return contentEffects?.first
		}
		set {
			guard responds(to: NSSelectorFromString("setContentEffects:")) else { return }
			var contentEffects = [UIVisualEffect]()
			if let effect = newValue {
				contentEffects = [effect]
			}
			setValue(contentEffects, forKey: "contentEffects")
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		subviews[0].layer.setValue(false, forKeyPath: "filters.gaussianBlur.inputNormalizeEdges")
	}
}

private extension UIBlurEffect {
	static func effect(withBlurRadius blurRadius: CGFloat) -> UIBlurEffect? {
		let selector = NSSelectorFromString("effectWithBlurRadius:")
		guard let implementation = UIBlurEffect.method(for: selector) else { return nil }
		let methodType = (@convention(c) (AnyClass, Selector, CGFloat) -> UIBlurEffect?).self
		let method = unsafeBitCast(implementation, to: methodType)
		return method(UIBlurEffect.self, selector, blurRadius)
	}
}
