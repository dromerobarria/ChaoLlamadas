//
//  ChaoLlamadasWidgetLiveActivity.swift
//  ChaoLlamadasWidget
//
//  Created by Daniel Romero on 27-08-25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ChaoLlamadasWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ChaoLlamadasWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChaoLlamadasWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ChaoLlamadasWidgetAttributes {
    fileprivate static var preview: ChaoLlamadasWidgetAttributes {
        ChaoLlamadasWidgetAttributes(name: "World")
    }
}

extension ChaoLlamadasWidgetAttributes.ContentState {
    fileprivate static var smiley: ChaoLlamadasWidgetAttributes.ContentState {
        ChaoLlamadasWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ChaoLlamadasWidgetAttributes.ContentState {
         ChaoLlamadasWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ChaoLlamadasWidgetAttributes.preview) {
   ChaoLlamadasWidgetLiveActivity()
} contentStates: {
    ChaoLlamadasWidgetAttributes.ContentState.smiley
    ChaoLlamadasWidgetAttributes.ContentState.starEyes
}
