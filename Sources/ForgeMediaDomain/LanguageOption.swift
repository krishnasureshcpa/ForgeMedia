import Foundation

/// A spoken language that ForgeMedia can detect or target for transcription/dubbing.
public struct LanguageOption: Identifiable, Hashable, Sendable, Codable {
    /// BCP-47 / ISO 639-1 code, e.g. "en", "es", "zh"
    public var id: String
    /// English display name
    public var name: String
    /// Name as written in the language itself
    public var nativeName: String
    /// Whisper model language code (same as ISO 639-1 for supported languages)
    public var whisperCode: String

    public init(id: String, name: String, nativeName: String, whisperCode: String? = nil) {
        self.id = id
        self.name = name
        self.nativeName = nativeName
        self.whisperCode = whisperCode ?? id
    }
}

// MARK: - Catalog

public extension LanguageOption {
    /// Auto-detect — let the engine decide the source language.
    static let auto = LanguageOption(id: "auto", name: "Auto-detect", nativeName: "Auto-detect")
    /// Unknown / unconfirmed (used during detection)
    static let unknown = LanguageOption(id: "und", name: "Unknown", nativeName: "Unknown")

    /// All supported languages, ordered alphabetically by English name.
    static let all: [LanguageOption] = [
        .init(id: "af", name: "Afrikaans",     nativeName: "Afrikaans"),
        .init(id: "sq", name: "Albanian",      nativeName: "Shqip"),
        .init(id: "am", name: "Amharic",       nativeName: "አማርኛ"),
        .init(id: "ar", name: "Arabic",        nativeName: "العربية"),
        .init(id: "hy", name: "Armenian",      nativeName: "Հայերեն"),
        .init(id: "az", name: "Azerbaijani",   nativeName: "Azərbaycan"),
        .init(id: "eu", name: "Basque",        nativeName: "Euskara"),
        .init(id: "be", name: "Belarusian",    nativeName: "Беларуская"),
        .init(id: "bn", name: "Bengali",       nativeName: "বাংলা"),
        .init(id: "bs", name: "Bosnian",       nativeName: "Bosanski"),
        .init(id: "bg", name: "Bulgarian",     nativeName: "Български"),
        .init(id: "ca", name: "Catalan",       nativeName: "Català"),
        .init(id: "zh", name: "Chinese (Simplified)",  nativeName: "中文（简体）"),
        .init(id: "zh-TW", name: "Chinese (Traditional)", nativeName: "中文（繁體）", whisperCode: "zh"),
        .init(id: "hr", name: "Croatian",      nativeName: "Hrvatski"),
        .init(id: "cs", name: "Czech",         nativeName: "Čeština"),
        .init(id: "da", name: "Danish",        nativeName: "Dansk"),
        .init(id: "nl", name: "Dutch",         nativeName: "Nederlands"),
        .init(id: "en", name: "English",       nativeName: "English"),
        .init(id: "et", name: "Estonian",      nativeName: "Eesti"),
        .init(id: "fi", name: "Finnish",       nativeName: "Suomi"),
        .init(id: "fr", name: "French",        nativeName: "Français"),
        .init(id: "gl", name: "Galician",      nativeName: "Galego"),
        .init(id: "ka", name: "Georgian",      nativeName: "ქართული"),
        .init(id: "de", name: "German",        nativeName: "Deutsch"),
        .init(id: "el", name: "Greek",         nativeName: "Ελληνικά"),
        .init(id: "gu", name: "Gujarati",      nativeName: "ગુજરાતી"),
        .init(id: "ht", name: "Haitian Creole",nativeName: "Kreyòl ayisyen"),
        .init(id: "ha", name: "Hausa",         nativeName: "Hausa"),
        .init(id: "he", name: "Hebrew",        nativeName: "עברית"),
        .init(id: "hi", name: "Hindi",         nativeName: "हिन्दी"),
        .init(id: "hu", name: "Hungarian",     nativeName: "Magyar"),
        .init(id: "is", name: "Icelandic",     nativeName: "Íslenska"),
        .init(id: "ig", name: "Igbo",          nativeName: "Igbo"),
        .init(id: "id", name: "Indonesian",    nativeName: "Bahasa Indonesia"),
        .init(id: "ga", name: "Irish",         nativeName: "Gaeilge"),
        .init(id: "it", name: "Italian",       nativeName: "Italiano"),
        .init(id: "ja", name: "Japanese",      nativeName: "日本語"),
        .init(id: "jv", name: "Javanese",      nativeName: "Basa Jawa"),
        .init(id: "kn", name: "Kannada",       nativeName: "ಕನ್ನಡ"),
        .init(id: "kk", name: "Kazakh",        nativeName: "Қазақша"),
        .init(id: "km", name: "Khmer",         nativeName: "ខ្មែរ"),
        .init(id: "ko", name: "Korean",        nativeName: "한국어"),
        .init(id: "ku", name: "Kurdish",       nativeName: "Kurdî"),
        .init(id: "ky", name: "Kyrgyz",        nativeName: "Кыргызча"),
        .init(id: "lo", name: "Lao",           nativeName: "ລາວ"),
        .init(id: "lv", name: "Latvian",       nativeName: "Latviešu"),
        .init(id: "lt", name: "Lithuanian",    nativeName: "Lietuvių"),
        .init(id: "lb", name: "Luxembourgish", nativeName: "Lëtzebuergesch"),
        .init(id: "mk", name: "Macedonian",    nativeName: "Македонски"),
        .init(id: "ms", name: "Malay",         nativeName: "Bahasa Melayu"),
        .init(id: "ml", name: "Malayalam",     nativeName: "മലയാളം"),
        .init(id: "mt", name: "Maltese",       nativeName: "Malti"),
        .init(id: "mr", name: "Marathi",       nativeName: "मराठी"),
        .init(id: "mn", name: "Mongolian",     nativeName: "Монгол"),
        .init(id: "my", name: "Myanmar (Burmese)", nativeName: "မြန်မာ"),
        .init(id: "ne", name: "Nepali",        nativeName: "नेपाली"),
        .init(id: "no", name: "Norwegian",     nativeName: "Norsk"),
        .init(id: "or", name: "Odia",          nativeName: "ଓଡ଼ିଆ"),
        .init(id: "ps", name: "Pashto",        nativeName: "پښتو"),
        .init(id: "fa", name: "Persian",       nativeName: "فارسی"),
        .init(id: "pl", name: "Polish",        nativeName: "Polski"),
        .init(id: "pt", name: "Portuguese",    nativeName: "Português"),
        .init(id: "pt-BR", name: "Portuguese (Brazil)", nativeName: "Português Brasileiro", whisperCode: "pt"),
        .init(id: "pa", name: "Punjabi",       nativeName: "ਪੰਜਾਬੀ"),
        .init(id: "ro", name: "Romanian",      nativeName: "Română"),
        .init(id: "ru", name: "Russian",       nativeName: "Русский"),
        .init(id: "sm", name: "Samoan",        nativeName: "Gagana Samoa"),
        .init(id: "gd", name: "Scottish Gaelic", nativeName: "Gàidhlig"),
        .init(id: "sr", name: "Serbian",       nativeName: "Српски"),
        .init(id: "sn", name: "Shona",         nativeName: "chiShona"),
        .init(id: "sd", name: "Sindhi",        nativeName: "سنڌي"),
        .init(id: "si", name: "Sinhala",       nativeName: "සිංහල"),
        .init(id: "sk", name: "Slovak",        nativeName: "Slovenčina"),
        .init(id: "sl", name: "Slovenian",     nativeName: "Slovenščina"),
        .init(id: "so", name: "Somali",        nativeName: "Soomaali"),
        .init(id: "es", name: "Spanish",       nativeName: "Español"),
        .init(id: "su", name: "Sundanese",     nativeName: "Basa Sunda"),
        .init(id: "sw", name: "Swahili",       nativeName: "Kiswahili"),
        .init(id: "sv", name: "Swedish",       nativeName: "Svenska"),
        .init(id: "tl", name: "Tagalog",       nativeName: "Tagalog"),
        .init(id: "tg", name: "Tajik",         nativeName: "Тоҷикӣ"),
        .init(id: "ta", name: "Tamil",         nativeName: "தமிழ்"),
        .init(id: "tt", name: "Tatar",         nativeName: "Татарча"),
        .init(id: "te", name: "Telugu",        nativeName: "తెలుగు"),
        .init(id: "th", name: "Thai",          nativeName: "ไทย"),
        .init(id: "tr", name: "Turkish",       nativeName: "Türkçe"),
        .init(id: "tk", name: "Turkmen",       nativeName: "Türkmen"),
        .init(id: "ug", name: "Uyghur",        nativeName: "ئۇيغۇرچە"),
        .init(id: "uk", name: "Ukrainian",     nativeName: "Українська"),
        .init(id: "ur", name: "Urdu",          nativeName: "اردو"),
        .init(id: "uz", name: "Uzbek",         nativeName: "O'zbek"),
        .init(id: "vi", name: "Vietnamese",    nativeName: "Tiếng Việt"),
        .init(id: "cy", name: "Welsh",         nativeName: "Cymraeg"),
        .init(id: "xh", name: "Xhosa",         nativeName: "isiXhosa"),
        .init(id: "yi", name: "Yiddish",       nativeName: "יידיש"),
        .init(id: "yo", name: "Yoruba",        nativeName: "Yorùbá"),
        .init(id: "zu", name: "Zulu",          nativeName: "isiZulu"),
    ]

    /// Look up a language by BCP-47 id. Falls back to `.unknown`.
    static func find(id: String) -> LanguageOption {
        all.first(where: { $0.id == id }) ?? unknown
    }

    /// Look up by common ffprobe language short codes (e.g. "spa" → "es").
    static func fromISO639_2(code: String) -> LanguageOption? {
        let map: [String: String] = [
            "afr":"af","alb":"sq","amh":"am","ara":"ar","hye":"hy","arm":"hy",
            "aze":"az","baq":"eu","bel":"be","ben":"bn","bos":"bs","bul":"bg",
            "cat":"ca","zho":"zh","chi":"zh","hrv":"hr","cze":"cs","dan":"da",
            "dut":"nl","nld":"nl","eng":"en","est":"et","fin":"fi","fre":"fr",
            "fra":"fr","glg":"gl","kat":"ka","geo":"ka","ger":"de","deu":"de",
            "gre":"el","ell":"el","guj":"gu","hat":"ht","hau":"ha","heb":"he",
            "hin":"hi","hun":"hu","isl":"is","ice":"is","ibo":"ig","ind":"id",
            "gle":"ga","ita":"it","jpn":"ja","jav":"jv","kan":"kn","kaz":"kk",
            "khm":"km","kor":"ko","kur":"ku","kir":"ky","lao":"lo","lav":"lv",
            "lit":"lt","ltz":"lb","mac":"mk","mkd":"mk","msa":"ms","mal":"ml",
            "mlt":"mt","mar":"mr","mon":"mn","bur":"my","mya":"my","nep":"ne",
            "nor":"no","ori":"or","pus":"ps","per":"fa","fas":"fa","pol":"pl",
            "por":"pt","pan":"pa","rum":"ro","ron":"ro","rus":"ru","smo":"sm",
            "srp":"sr","sna":"sn","snd":"sd","sin":"si","slo":"sk","slv":"sl",
            "som":"so","spa":"es","sun":"su","swa":"sw","swe":"sv","tgl":"tl",
            "tgk":"tg","tam":"ta","tat":"tt","tel":"te","tha":"th","tur":"tr",
            "tuk":"tk","uig":"ug","ukr":"uk","urd":"ur","uzb":"uz","vie":"vi",
            "wel":"cy","cym":"cy","xho":"xh","yid":"yi","yor":"yo","zul":"zu",
        ]
        guard let iso1 = map[code.lowercased()] else { return nil }
        return all.first(where: { $0.id == iso1 })
    }
}

// MARK: - Detection Result

public struct LanguageDetectionResult: Sendable, Equatable {
    public enum Source: String, Sendable { case metadata, heuristic, whisper, gemini, manual }

    public var language: LanguageOption
    public var confidence: Double   // 0.0 – 1.0
    public var source: Source
    public var needsUserConfirmation: Bool

    public init(language: LanguageOption, confidence: Double, source: Source, needsUserConfirmation: Bool? = nil) {
        self.language = language
        self.confidence = confidence
        self.source = source
        self.needsUserConfirmation = needsUserConfirmation ?? (confidence < 0.85 || language.id == "und")
    }

    public static let unknown = LanguageDetectionResult(
        language: .unknown, confidence: 0, source: .metadata, needsUserConfirmation: true
    )
}
