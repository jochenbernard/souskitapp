/// How far the cook has come with one step.
enum StepProgress {
    /// Ticked off.
    case done

    /// The first step not yet ticked off, which the cook is on.
    case current

    /// Not ticked off, after the current step.
    case upcoming
}
