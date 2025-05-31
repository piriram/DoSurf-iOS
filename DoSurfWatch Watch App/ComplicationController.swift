import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "surf_last_session",
                displayName: "Last Surf Session",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicExtraLarge
                ]
            )
        ]
        
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Return a date in the future after which we no longer have data
        handler(Date().addingTimeInterval(24 * 60 * 60)) // 24시간 후
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Complication data is not sensitive
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        
        guard let template = createTemplate(for: complication) else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // No future entries needed for this complication
        handler([])
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createPlaceholderTemplate(for: complication)
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        let lastSession = ComplicationDataManager.shared.getLastSession()
        
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(lastSession: lastSession)
        case .modularLarge:
            return createModularLargeTemplate(lastSession: lastSession)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(lastSession: lastSession)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(lastSession: lastSession)
        case .circularSmall:
            return createCircularSmallTemplate(lastSession: lastSession)
        case .extraLarge:
            return createExtraLargeTemplate(lastSession: lastSession)
        case .graphicCorner:
            return createGraphicCornerTemplate(lastSession: lastSession)
        case .graphicCircular:
            return createGraphicCircularTemplate(lastSession: lastSession)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(lastSession: lastSession)
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                return createGraphicExtraLargeTemplate(lastSession: lastSession)
            }
            return nil
        @unknown default:
            return nil
        }
    }
    
    private func createPlaceholderTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        // Create placeholder templates with sample data
        let sampleSession = ComplicationDataManager.LastSessionData(
            duration: 1800, // 30 minutes
            distance: 500,
            waveCount: 12,
            date: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(lastSession: sampleSession)
        case .modularLarge:
            return createModularLargeTemplate(lastSession: sampleSession)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(lastSession: sampleSession)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(lastSession: sampleSession)
        case .circularSmall:
            return createCircularSmallTemplate(lastSession: sampleSession)
        case .extraLarge:
            return createExtraLargeTemplate(lastSession: sampleSession)
        case .graphicCorner:
            return createGraphicCornerTemplate(lastSession: sampleSession)
        case .graphicCircular:
            return createGraphicCircularTemplate(lastSession: sampleSession)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(lastSession: sampleSession)
        case .graphicExtraLarge:
            if #available(watchOS 7.0, *) {
                return createGraphicExtraLargeTemplate(lastSession: sampleSession)
            }
            return nil
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Individual Template Creators
    
    private func createModularSmallTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateModularSmallSimpleText {
        let template = CLKComplicationTemplateModularSmallSimpleText()
        
        if let session = lastSession {
            template.textProvider = CLKSimpleTextProvider(text: session.formattedDuration)
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "--:--")
        }
        
        return template
    }
    
    private func createModularLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateModularLargeStandardBody {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "🏄‍♂️ Last Surf")
        
        if let session = lastSession {
            template.body1TextProvider = CLKSimpleTextProvider(text: session.formattedDuration)
            template.body2TextProvider = CLKSimpleTextProvider(text: session.shortSummary)
        } else {
            template.body1TextProvider = CLKSimpleTextProvider(text: "No sessions yet")
            template.body2TextProvider = CLKSimpleTextProvider(text: "Start surfing!")
        }
        
        return template
    }
    
    private func createUtilitarianSmallTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        
        if let session = lastSession {
            template.textProvider = CLKSimpleTextProvider(text: session.formattedDuration)
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "--:--")
        }
        
        return template
    }
    
    private func createUtilitarianLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        
        if let session = lastSession {
            template.textProvider = CLKSimpleTextProvider(text: "🏄‍♂️ \(session.formattedDuration) • \(session.waveCount)🌊")
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "🏄‍♂️ No sessions yet")
        }
        
        return template
    }
    
    private func createCircularSmallTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateCircularSmallSimpleText {
        let template = CLKComplicationTemplateCircularSmallSimpleText()
        
        if let session = lastSession {
            let minutes = Int(session.duration) / 60
            template.textProvider = CLKSimpleTextProvider(text: "\(minutes)m")
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "--")
        }
        
        return template
    }
    
    private func createExtraLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateExtraLargeSimpleText {
        let template = CLKComplicationTemplateExtraLargeSimpleText()
        
        if let session = lastSession {
            template.textProvider = CLKSimpleTextProvider(text: session.formattedDuration)
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "--:--")
        }
        
        return template
    }
    
    private func createGraphicCornerTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicCornerTextImage {
        let template = CLKComplicationTemplateGraphicCornerTextImage()
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "figure.surfing") ?? UIImage())
        
        if let session = lastSession {
            template.textProvider = CLKSimpleTextProvider(text: session.formattedDuration)
        } else {
            template.textProvider = CLKSimpleTextProvider(text: "--:--")
        }
        
        return template
    }
    
    private func createGraphicCircularTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicCircularImage {
        let template = CLKComplicationTemplateGraphicCircularImage()
        template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "figure.surfing") ?? UIImage())
        return template
    }
    
    private func createGraphicRectangularTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicRectangularStandardBody {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()
        template.headerImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "figure.surfing") ?? UIImage())
        template.headerTextProvider = CLKSimpleTextProvider(text: "Last Surf")
        
        if let session = lastSession {
            template.body1TextProvider = CLKSimpleTextProvider(text: session.formattedDuration)
            template.body2TextProvider = CLKSimpleTextProvider(text: "\(Int(session.distance))m • \(session.waveCount) waves")
        } else {
            template.body1TextProvider = CLKSimpleTextProvider(text: "No sessions")
            template.body2TextProvider = CLKSimpleTextProvider(text: "Start surfing!")
        }
        
        return template
    }
    
    @available(watchOS 7.0, *)
    private func createGraphicExtraLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicExtraLargeCircularView<some View> {
        if let session = lastSession {
            let contentView = VStack(spacing: 4) {
                Image(systemName: "figure.surfing")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text(session.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("\(session.waveCount) waves")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            return CLKComplicationTemplateGraphicExtraLargeCircularView(contentView)
        } else {
            let contentView = VStack(spacing: 4) {
                Image(systemName: "figure.surfing")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("--:--")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("No sessions")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            return CLKComplicationTemplateGraphicExtraLargeCircularView(contentView)
        }
    }
}
