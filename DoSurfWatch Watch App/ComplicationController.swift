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
                    .utilitarianSmallFlat,
                    .utilitarianLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicBezel,
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
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallTemplate(lastSession: lastSession)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(lastSession: lastSession)
        case .circularSmall:
            return createCircularSmallTemplate(lastSession: lastSession)
        case .extraLarge:
            return createExtraLargeTemplate(lastSession: lastSession)
        case .graphicCorner:
            return createGraphicCornerTemplate(lastSession: lastSession)
        case .graphicBezel:
            return createGraphicBezelTemplate(lastSession: lastSession)
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
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallTemplate(lastSession: sampleSession)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(lastSession: sampleSession)
        case .circularSmall:
            return createCircularSmallTemplate(lastSession: sampleSession)
        case .extraLarge:
            return createExtraLargeTemplate(lastSession: sampleSession)
        case .graphicCorner:
            return createGraphicCornerTemplate(lastSession: sampleSession)
        case .graphicBezel:
            return createGraphicBezelTemplate(lastSession: sampleSession)
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
        let textProvider = CLKSimpleTextProvider(text: lastSession?.formattedDuration ?? "--:--")
        return CLKComplicationTemplateModularSmallSimpleText(textProvider: textProvider)
    }
    
    private func createModularLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateModularLargeStandardBody {
        let header = CLKSimpleTextProvider(text: "🏄‍♂️ Last Surf")
        let body1 = CLKSimpleTextProvider(text: lastSession?.formattedDuration ?? "No sessions yet")
        let body2 = CLKSimpleTextProvider(text: lastSession?.shortSummary ?? "Start surfing!")

        return CLKComplicationTemplateModularLargeStandardBody(
            headerTextProvider: header,
            body1TextProvider: body1,
            body2TextProvider: body2
        )
    }
    
    private func createUtilitarianSmallTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateUtilitarianSmallFlat {
        let textProvider = CLKSimpleTextProvider(text: lastSession?.formattedDuration ?? "--:--")
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: textProvider)
    }
    
    private func createUtilitarianLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateUtilitarianLargeFlat {
        let text: String
        if let session = lastSession {
            text = "🏄‍♂️ \(session.formattedDuration) • \(session.waveCount)🌊"
        } else {
            text = "🏄‍♂️ No sessions yet"
        }

        return CLKComplicationTemplateUtilitarianLargeFlat(
            textProvider: CLKSimpleTextProvider(text: text)
        )
    }
    
    private func createCircularSmallTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateCircularSmallSimpleText {
        let text: String
        if let session = lastSession {
            let minutes = Int(session.duration) / 60
            text = "\(minutes)m"
        } else {
            text = "--"
        }

        return CLKComplicationTemplateCircularSmallSimpleText(
            textProvider: CLKSimpleTextProvider(text: text)
        )
    }
    
    private func createExtraLargeTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateExtraLargeSimpleText {
        let textProvider = CLKSimpleTextProvider(text: lastSession?.formattedDuration ?? "--:--")
        return CLKComplicationTemplateExtraLargeSimpleText(textProvider: textProvider)
    }
    
    private func createGraphicCornerTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicCornerTextImage {
        let textProvider = CLKSimpleTextProvider(text: lastSession?.formattedDuration ?? "--:--")
        let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "figure.surfing") ?? UIImage())
        return CLKComplicationTemplateGraphicCornerTextImage(
            textProvider: textProvider,
            imageProvider: imageProvider
        )
    }
    
    private func createGraphicCircularTemplate(lastSession _: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicCircularImage {
        let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "figure.surfing") ?? UIImage())
        return CLKComplicationTemplateGraphicCircularImage(imageProvider: imageProvider)
    }

    private func createGraphicBezelTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicBezelCircularText {
        let circularTemplate = createGraphicCircularTemplate(lastSession: lastSession)
        let text = lastSession?.formattedDuration ?? "--:--"
        return CLKComplicationTemplateGraphicBezelCircularText(
            circularTemplate: circularTemplate,
            textProvider: CLKSimpleTextProvider(text: text)
        )
    }
    
    private func createGraphicRectangularTemplate(lastSession: ComplicationDataManager.LastSessionData?) -> CLKComplicationTemplateGraphicRectangularStandardBody {
        let headerImageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "figure.surfing") ?? UIImage())
        let headerTextProvider = CLKSimpleTextProvider(text: "Last Surf")

        let body1Text: String
        let body2Text: String
        if let session = lastSession {
            body1Text = session.formattedDuration
            body2Text = "\(Int(session.distance))m • \(session.waveCount) waves"
        } else {
            body1Text = "No sessions"
            body2Text = "Start surfing!"
        }

        return CLKComplicationTemplateGraphicRectangularStandardBody(
            headerImageProvider: headerImageProvider,
            headerTextProvider: headerTextProvider,
            body1TextProvider: CLKSimpleTextProvider(text: body1Text),
            body2TextProvider: CLKSimpleTextProvider(text: body2Text)
        )
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
