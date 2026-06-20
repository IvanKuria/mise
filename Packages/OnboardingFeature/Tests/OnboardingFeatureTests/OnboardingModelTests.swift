import Testing
@testable import OnboardingFeature

@Suite("Handle normalization")
struct HandleNormalizationTests {

    @Test("Plain handle passes through")
    func plainHandle() {
        #expect(OnboardingModel.normalizeHandle("davidfincher") == "davidfincher")
    }

    @Test("Surrounding whitespace is trimmed")
    func trimsWhitespace() {
        #expect(OnboardingModel.normalizeHandle("  davidfincher \n") == "davidfincher")
    }

    @Test("Leading @ is stripped")
    func stripsAtSign() {
        #expect(OnboardingModel.normalizeHandle("@davidfincher") == "davidfincher")
    }

    @Test("Full https URL is reduced to the handle")
    func fullURL() {
        #expect(
            OnboardingModel.normalizeHandle("https://letterboxd.com/davidfincher/")
                == "davidfincher"
        )
    }

    @Test("URL with extra path segments keeps only the username")
    func urlWithSubpath() {
        #expect(
            OnboardingModel.normalizeHandle("https://letterboxd.com/davidfincher/films/diary/")
                == "davidfincher"
        )
    }

    @Test("Schemeless host is handled")
    func schemelessHost() {
        #expect(
            OnboardingModel.normalizeHandle("letterboxd.com/davidfincher")
                == "davidfincher"
        )
    }

    @Test("www and http variants are handled")
    func wwwAndHttp() {
        #expect(
            OnboardingModel.normalizeHandle("http://www.letterboxd.com/Some_User/")
                == "Some_User"
        )
    }

    @Test("Underscores and digits are valid")
    func underscoresAndDigits() {
        #expect(OnboardingModel.normalizeHandle("user_123") == "user_123")
    }

    @Test("Empty / whitespace-only input is nil")
    func emptyIsNil() {
        #expect(OnboardingModel.normalizeHandle("") == nil)
        #expect(OnboardingModel.normalizeHandle("   ") == nil)
    }

    @Test("Just an @ is nil")
    func lonelyAtSign() {
        #expect(OnboardingModel.normalizeHandle("@") == nil)
    }

    @Test("URL with no username segment is nil")
    func urlNoUser() {
        #expect(OnboardingModel.normalizeHandle("https://letterboxd.com/") == nil)
    }

    @Test("Handles with illegal characters are rejected")
    func illegalCharacters() {
        #expect(OnboardingModel.normalizeHandle("bad name") == nil)
        #expect(OnboardingModel.normalizeHandle("has.dot") == nil)
        #expect(OnboardingModel.normalizeHandle("emoji😀") == nil)
    }
}

@Suite("Handle validity")
struct HandleValidityTests {
    @Test("Valid charset accepted")
    func valid() {
        #expect(OnboardingModel.isValidHandle("aZ0_9"))
    }

    @Test("Empty rejected")
    func empty() {
        #expect(!OnboardingModel.isValidHandle(""))
    }

    @Test("Punctuation rejected")
    func punctuation() {
        #expect(!OnboardingModel.isValidHandle("a-b"))
        #expect(!OnboardingModel.isValidHandle("a b"))
    }
}

@Suite("TMDB key normalization")
struct TMDBKeyTests {
    @Test("Blank key is nil")
    func blank() {
        #expect(OnboardingModel.normalizeTMDBKey("") == nil)
        #expect(OnboardingModel.normalizeTMDBKey("   \n") == nil)
    }

    @Test("Real key is trimmed")
    func trimmed() {
        #expect(OnboardingModel.normalizeTMDBKey("  abc123  ") == "abc123")
    }
}

@Suite("Model state")
@MainActor
struct ModelStateTests {
    @Test("canSubmit is false without a valid handle")
    func cannotSubmitWhenInvalid() {
        let model = OnboardingModel(handle: "")
        #expect(!model.canSubmit)
        #expect(model.normalizedHandle == nil)
    }

    @Test("canSubmit is true with a valid handle while idle")
    func canSubmitWhenValid() {
        let model = OnboardingModel(handle: "letterboxd.com/davidfincher")
        #expect(model.normalizedHandle == "davidfincher")
        #expect(model.canSubmit)
    }

    @Test("canSubmit is false while syncing even with a valid handle")
    func cannotSubmitWhileSyncing() {
        let model = OnboardingModel(
            handle: "davidfincher",
            status: .syncing(progress: 0.4, message: "Loading diary…")
        )
        #expect(!model.canSubmit)
        #expect(model.status.isSyncing)
    }

    @Test("normalizedTMDBKey reflects the field")
    func tmdbKeyDerived() {
        let model = OnboardingModel(handle: "x", tmdbKey: "  key  ")
        #expect(model.normalizedTMDBKey == "key")
    }

    @Test("Status equality and isSyncing flag")
    func statusFlags() {
        #expect(!OnboardingModel.Status.idle.isSyncing)
        #expect(!OnboardingModel.Status.done.isSyncing)
        #expect(!OnboardingModel.Status.failed("nope").isSyncing)
        #expect(OnboardingModel.Status.syncing(progress: 0, message: "x").isSyncing)
    }
}
