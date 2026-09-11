/// One run of a step's prose, and what the source wrote it as.
public struct StepRun: Sendable, Equatable {
    /// The words the run reads as.
    public let text: String

    /// Whether the run stands for an annotation, which is something the step reaches for.
    public let isAnnotation: Bool
}
