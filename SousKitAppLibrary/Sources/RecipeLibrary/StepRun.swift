/// One run of a step's prose, and what the source wrote it as.
struct StepRun: Sendable, Equatable {
    /// The words the run reads as.
    let text: String

    /// Whether the run stands for an annotation, which is something the step reaches for.
    let isAnnotation: Bool
}
