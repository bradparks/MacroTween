package macrotween;

class Cue extends TimelineItem {
	public function new(startTime:Float, ?enterLeft:Bool->Int->Void, ?exitRight:Bool->Int->Void, ?enterRight:Bool->Int->Void, ?exitLeft:Bool->Int->Void, removeOnCompletion:Bool = false) {
		super(null, startTime, 0);
		this.removeOnCompletion = removeOnCompletion;

		if (enterLeft != null) {
			left.add(enterLeft);
		}
		if (enterRight != null) {
			right.add(enterRight);
		}
		if (exitLeft != null) {
			left.add(exitLeft);
		}
		if (exitRight != null) {
			right.add(exitRight);
		}
	}
}