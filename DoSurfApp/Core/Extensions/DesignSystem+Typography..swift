import UIKit
import CoreText

// MARK: - Font Provider Protocol
protocol FontProviderProtocol {
    func font(size: CGFloat, weight: UIFont.Weight) -> UIFont
    func registerFonts()
}

// MARK: - Usage Examples and Documentation
/*
 
 USAGE EXAMPLES:
 
 1. 기본 사용 (시스템 폰트):
 label.setTextWithTypography("Hello", style: .hero)
 
 2. 커스텀 폰트로 전환 (나중에 폰트 파일 추가 후):
 TypographySystem.useCustomFont()
 label.setTextWithTypography("Hello", style: .hero) // 이제 커스텀 폰트 사용
 
 3. 다시 시스템 폰트로 되돌리기:
 TypographySystem.useSystemFont()
 
 4. 폰트 파일 추가 방법 (나중에):
 - .ttf 또는 .otf 파일을 프로젝트에 추가
 - CustomFontProvider의 fontFamily 변수를 실제 폰트명으로 수정
 - fontName(for:) 메서드에서 각 weight별 폰트명 정의
 
 FONT INTEGRATION CHECKLIST (커스텀 폰트 추가 시):
 □ 폰트 파일들을 Bundle에 추가
 □ Info.plist에 "Fonts provided by application" 배열 추가 (선택사항)
 □ CustomFontProvider.fontFamily 이름 수정
 □ CustomFontProvider.fontName(for:) 메서드에서 각 weight별 폰트명 매핑
 □ TypographySystem.useCustomFont() 호출
 
 */

// MARK: - System Font Provider
class SystemFontProvider: FontProviderProtocol {
    static let shared = SystemFontProvider()
    private init() {}
    
    func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: weight)
    }
    
    func registerFonts() {}
}

// MARK: - Custom Font Provider
class CustomFontProvider: FontProviderProtocol {
    static let shared = CustomFontProvider()
    
    // 폰트 패밀리 이름 설정 (나중에 실제 폰트로 교체)
    private let fontFamily = "YourCustomFont" // 실제 폰트명으로 교체 예정
    private var isRegistered = false
    
    private init() {}
    
    func font(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        registerFonts() // 필요시 폰트 등록
        
        // 폰트 가중치에 따른 실제 폰트명 매핑
        let fontName = fontName(for: weight)
        
        // 커스텀 폰트 로드 시도
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont
        } else {
            // Fallback to system font
            print("⚠️ Custom font '\(fontName)' not found, falling back to system font")
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
    }
    
    func registerFonts() {
        guard !isRegistered else { return }
        
        // 번들에서 폰트 파일들을 찾아서 등록
        registerFontFiles()
        isRegistered = true
    }
    
    private func fontName(for weight: UIFont.Weight) -> String {
        switch weight {
        case .ultraLight: return "\(fontFamily)-UltraLight"
        case .thin: return "\(fontFamily)-Thin"
        case .light: return "\(fontFamily)-Light"
        case .regular: return "\(fontFamily)-Regular"
        case .medium: return "\(fontFamily)-Medium"
        case .semibold: return "\(fontFamily)-SemiBold"
        case .bold: return "\(fontFamily)-Bold"
        case .heavy: return "\(fontFamily)-Heavy"
        case .black: return "\(fontFamily)-Black"
        default: return "\(fontFamily)-Regular"
        }
    }
    
    private func registerFontFiles() {
        let fontExtensions = ["ttf", "otf"]
        
        for ext in fontExtensions {
            if let fontURLs = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                for fontURL in fontURLs {
                    registerFont(from: fontURL)
                }
            }
        }
    }
    
    private func registerFont(from url: URL) {
        guard let fontDataProvider = CGDataProvider(url: url as CFURL),
              let font = CGFont(fontDataProvider) else {
            print("⚠️ Failed to load font from: \(url)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            if let error = error {
                let errorDescription = CFErrorCopyDescription(error.takeUnretainedValue())
                print("⚠️ Failed to register font: \(errorDescription ?? "Unknown error" as CFString)")
            }
        }
    }
}

// MARK: - Typography Style Definition
enum TypographyStyle: CaseIterable {
    case hero
    case heading1
    case heading2Medium
    case heading3Medium
    case subheadingBold
    case subheadingMedium
    case body1Medium
    case body2Medium
    case captionMedium
    
    var name: String {
        switch self {
        case .hero: return "Hero"
        case .heading1: return "Heading1"
        case .heading2Medium: return "Heading2 Bold"
        case .heading3Medium: return "Heading3 Bold"
        case .subheadingBold: return "Subheading Bold"
        case .subheadingMedium: return "Subheading Bold"
        case .body1Medium: return "Body1 Bold"
        case .body2Medium: return "Body2 Bold"
        case .captionMedium: return "Caption Bold"
        }
    }
}

// MARK: - Typography Configuration
struct TypographyConfiguration {
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let letterSpacing: CGFloat // Percentage value (e.g., -4 for -4%)
    let fontWeight: UIFont.Weight
    
    init(fontSize: CGFloat, lineHeight: CGFloat, letterSpacing: CGFloat, fontWeight: UIFont.Weight = .regular) {
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.fontWeight = fontWeight
    }
    
    var kernValue: CGFloat {
        return fontSize * (letterSpacing / 100.0)
    }
    
    var lineSpacing: CGFloat {
        return lineHeight - fontSize
    }
}

// MARK: - Device Type Detection
enum DeviceType {
    case iPhone
    case iPad
    
    static var current: DeviceType {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return .iPhone
        case .pad: return .iPad
        default: return .iPhone
        }
    }
}

// MARK: - Typography System
class TypographySystem {
    
    // MARK: - Font Provider Switching
    private(set) static var currentFontProvider: FontProviderProtocol = SystemFontProvider.shared
    
    static func useCustomFont() {
        currentFontProvider = CustomFontProvider.shared
        currentFontProvider.registerFonts()
    }
    
    static func useSystemFont() {
        currentFontProvider = SystemFontProvider.shared
    }
    
    // MARK: - Configuration Data
    private static let configurations: [TypographyStyle: [DeviceType: TypographyConfiguration]] = [
        .hero: [
            .iPad: TypographyConfiguration(fontSize: 56, lineHeight: 65, letterSpacing: -4, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 36, lineHeight: 48, letterSpacing: -4, fontWeight: .medium)
        ],
        .heading1: [
            .iPad: TypographyConfiguration(fontSize: 38, lineHeight: 45, letterSpacing: -4, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 32, lineHeight: 38, letterSpacing: -4, fontWeight: .medium)
        ],
        .heading2Medium: [
            .iPad: TypographyConfiguration(fontSize: 28, lineHeight: 36, letterSpacing: -4, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 24, lineHeight: 34, letterSpacing: -4, fontWeight: .medium)
        ],
        .heading3Medium: [
            .iPad: TypographyConfiguration(fontSize: 22, lineHeight: 33, letterSpacing: -4, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 21, lineHeight: 30, letterSpacing: -4, fontWeight: .medium)
        ],
        .subheadingBold: [
            .iPad: TypographyConfiguration(fontSize: 18, lineHeight: 27, letterSpacing: -2, fontWeight: .bold),
            .iPhone: TypographyConfiguration(fontSize: 18, lineHeight: 27, letterSpacing: -2, fontWeight: .bold)
        ],
        .subheadingMedium: [
            .iPad: TypographyConfiguration(fontSize: 18, lineHeight: 27, letterSpacing: -2, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 18, lineHeight: 27, letterSpacing: -2, fontWeight: .medium)
        ],
        .body1Medium: [
            .iPad: TypographyConfiguration(fontSize: 16, lineHeight: 24, letterSpacing: -2, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 16, lineHeight: 24, letterSpacing: -2, fontWeight: .medium)
        ],
        .body2Medium: [
            .iPad: TypographyConfiguration(fontSize: 14, lineHeight: 21, letterSpacing: -2, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 14, lineHeight: 21, letterSpacing: -2, fontWeight: .medium)
        ],
        .captionMedium: [
            .iPad: TypographyConfiguration(fontSize: 12, lineHeight: 18, letterSpacing: -2, fontWeight: .medium),
            .iPhone: TypographyConfiguration(fontSize: 12, lineHeight: 18, letterSpacing: -2, fontWeight: .medium)
        ]
    ]
    
    // MARK: - Public Methods
    static func configuration(for style: TypographyStyle, deviceType: DeviceType = DeviceType.current) -> TypographyConfiguration {
        return configurations[style]?[deviceType] ?? configurations[style]?[.iPhone] ?? TypographyConfiguration(fontSize: 16, lineHeight: 24, letterSpacing: 0)
    }
    
    static func font(for style: TypographyStyle, deviceType: DeviceType = DeviceType.current) -> UIFont {
        let config = configuration(for: style, deviceType: deviceType)
        return currentFontProvider.font(size: config.fontSize, weight: config.fontWeight)
    }
    
    static func attributedStringAttributes(for style: TypographyStyle, deviceType: DeviceType = DeviceType.current, textColor: UIColor = .label) -> [NSAttributedString.Key: Any] {
        let config = configuration(for: style, deviceType: deviceType)
        let font = currentFontProvider.font(size: config.fontSize, weight: config.fontWeight)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = config.lineSpacing
        paragraphStyle.minimumLineHeight = config.lineHeight
        paragraphStyle.maximumLineHeight = config.lineHeight
        
        return [
            .font: font,
            .foregroundColor: textColor,
            .kern: config.kernValue,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    static func applyStyle(_ style: TypographyStyle, to label: UILabel, deviceType: DeviceType = DeviceType.current, textColor: UIColor = .label) {
        let config = configuration(for: style, deviceType: deviceType)
        
        label.font = currentFontProvider.font(size: config.fontSize, weight: config.fontWeight)
        label.textColor = textColor
        
        // Apply line height and letter spacing if text is set
        if let text = label.text, !text.isEmpty {
            let attributes = attributedStringAttributes(for: style, deviceType: deviceType, textColor: textColor)
            label.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }
}

// MARK: - UILabel Extension
extension UILabel {
    
    func applyTypography(_ style: TypographyStyle, deviceType: DeviceType = DeviceType.current, color: UIColor = .label) {
        TypographySystem.applyStyle(style, to: self, deviceType: deviceType, textColor: color)
    }
    
    func setTextWithTypography(_ text: String, style: TypographyStyle, deviceType: DeviceType = DeviceType.current, color: UIColor = .label) {
        let attributes = TypographySystem.attributedStringAttributes(for: style, deviceType: deviceType, textColor: color)
        attributedText = NSAttributedString(string: text, attributes: attributes)
    }
}

// MARK: - UITextView Extension
extension UITextView {
    
    func applyTypography(_ style: TypographyStyle, deviceType: DeviceType = DeviceType.current, color: UIColor = .label) {
        let config = TypographySystem.configuration(for: style, deviceType: deviceType)
        font = TypographySystem.currentFontProvider.font(size: config.fontSize, weight: config.fontWeight)
        textColor = color
        
        // Apply full styling if text exists
        if let text = text, !text.isEmpty {
            let attributes = TypographySystem.attributedStringAttributes(for: style, deviceType: deviceType, textColor: color)
            attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }
    
    func setTextWithTypography(_ text: String, style: TypographyStyle, deviceType: DeviceType = DeviceType.current, color: UIColor = .label) {
        let attributes = TypographySystem.attributedStringAttributes(for: style, deviceType: deviceType, textColor: color)
        attributedText = NSAttributedString(string: text, attributes: attributes)
    }
}


// MARK: - Typography Preview (for testing)
class TypographyPreviewViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        populateTypographyExamples()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Typography System"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .leading
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func populateTypographyExamples() {
        for style in TypographyStyle.allCases {
            let label = UILabel()
            label.numberOfLines = 0
            label.setTextWithTypography(style.name, style: style)
            stackView.addArrangedSubview(label)
            
            // Add device type info
            let deviceConfig = TypographySystem.configuration(for: style)
            let infoLabel = UILabel()
            infoLabel.text = "Size: \(deviceConfig.fontSize)pt, Line: \(deviceConfig.lineHeight)pt, Spacing: \(deviceConfig.letterSpacing)%"
            infoLabel.font = UIFont.systemFont(ofSize: FontSize.twelve)
            infoLabel.textColor = .secondaryLabel
            stackView.addArrangedSubview(infoLabel)
        }
    }
}

