/// One run of a step's prose, and how the step draws it.
struct StepRun: Equatable {
    /// The words the run reads as.
    let text: String

    /// Whether the run takes the accent underline, which marks what a step reaches for.
    let isUnderlined: Bool
}
