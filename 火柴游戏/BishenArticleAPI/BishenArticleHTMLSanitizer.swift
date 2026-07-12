import Foundation

enum BishenArticleHTMLSanitizer {
    static func sanitizeBodyContent(from rawHTML: String) -> String {
        var content = extractBody(from: rawHTML)

        content = replacingMatches(
            in: content,
            pattern: #"<\s*(script|style|link|meta|iframe|object|embed)\b[^>]*>.*?<\s*/\s*\1\s*>"#,
            with: ""
        )
        content = replacingMatches(
            in: content,
            pattern: #"<\s*(link|meta|iframe|object|embed)\b[^>]*\/?\s*>"#,
            with: ""
        )
        content = replacingMatches(
            in: content,
            pattern: #"\s+on[a-zA-Z]+\s*=\s*(['"])[\s\S]*?\1"#,
            with: ""
        )

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractBody(from html: String) -> String {
        guard let bodyOpen = firstMatch(in: html, pattern: #"<body\b[^>]*>"#),
              let bodyClose = lastMatch(in: html, pattern: #"</body\s*>"#),
              bodyOpen.range.upperBound <= bodyClose.range.lowerBound,
              let contentRange = Range(
                NSRange(location: bodyOpen.range.upperBound, length: bodyClose.range.lowerBound - bodyOpen.range.upperBound),
                in: html
              ) else {
            return html
        }

        return String(html[contentRange])
    }

    private static func replacingMatches(in value: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return value
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.stringByReplacingMatches(in: value, range: range, withTemplate: replacement)
    }

    private static func firstMatch(in value: String, pattern: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.firstMatch(in: value, range: range)
    }

    private static func lastMatch(in value: String, pattern: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.matches(in: value, range: range).last
    }
}
