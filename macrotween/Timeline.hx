package macrotween;

import flixel.math.FlxMath;
import flixel.util.FlxSignal;
import macrotween.TimelineItem.Boundary;

class Timeline extends TimelineItem {
	public var currentTime(default, set):Float; // Setting this will skip to the absolute time without triggering items
	public var lastTime:Float;
	public var onReset(default, null) = new FlxSignal();

	public var items:List<TimelineItem>; // TODO an interval tree might be faster
	private var dirtyDuration:Bool;

	public function new() {
		super(null, 0, 0);
		items = new List<TimelineItem>();
		dirtyDuration = true;
		currentTime = 0;
	}

	// Step to a relative time on the timeline
	public function step(dt:Float):Void {
		stepTo(currentTime + dt, currentTime);
	}

	// Steps to an absolute time on the timeline
	// Boundary crossing callbacks of items are called in chronological order
	// The order that individual items are updated is undefined
	override public function stepTo(nextTime:Float, ?unusedCurrentTime:Float):Void {
		nextTime = FlxMath.bound(nextTime, 0, duration);

		if (currentTime == nextTime) {
			return;
		}
		
		//TODO hack... figure out better solution with Sam
		var currentTime = currentTime;
		this.currentTime = nextTime;

		removeMarked();

		// TODO this won't trigger the boundary callbacks, because intersection checks were moved from the superclass to the timeline
		super.stepTo(nextTime, currentTime);

		var intersections:Array<Boundary> = [];

		var gatherIntersections = function(item:TimelineItem) {
			Sure.sure(item.startTime <= item.endTime);

			var shouldStep:Bool = rangesIntersect(currentTime, nextTime, item.startTime, item.endTime);

			if (!shouldStep) {
				return;
			}

			var intersectLeft:Bool = pointRangeIntersection(item.startTime, currentTime, nextTime);
			var intersectRight:Bool = pointRangeIntersection(item.endTime, currentTime, nextTime);
			if (intersectLeft) {
				intersections.push(item.left);
			}
			if (intersectRight) {
				intersections.push(item.right);
			}
		}

		gatherIntersections(this);
		for (item in items) {
			gatherIntersections(item);
		}

		var reversing:Bool = currentTime > nextTime;

		// TODO sort by parent item start/end time
		//intersections.sort(function(a:Boundary, b:Boundary)) {

		//}

		for (boundary in intersections) {
			boundary.dispatch(reversing, reversing ? ++boundary.rightToLeftCount : ++boundary.leftToRightCount);
		}
		
		for (item in items) item.stepTo(nextTime, currentTime);

		removeMarked();
	}

	private inline function pointRangeIntersection(p:Float, x1:Float, x2:Float):Bool {
		return (p >= Math.min(x1, x2) && p <= Math.max(x1, x2));
	}

	private inline function rangesIntersect(x1:Float, x2:Float, y1:Float, y2:Float):Bool {
		return ((Math.min(x1, x2) <= Math.max(y1, y2)) && (Math.min(y1, y2) <= Math.max(x1, x2)));
	}

	public function addCue(target:Dynamic, f:Bool->Int->Void, startTime:Float):Cue {
		Sure.sure(target != null);

		var cue = new Cue(startTime, f);
		add(cue);
		return cue;
	}

	public function add(item:TimelineItem):Void {
		item.parent = this;
		items.add(item);
		dirtyDuration = true;
		return;
	}

	public function remove(item:TimelineItem):Void {
		Sure.sure(item != null);
		items.remove(item);
	}

	public function clear():Void {
		items = new List<TimelineItem>();
	}

	override public function reset():Void {
		super.reset();

		for (item in items) {
			item.reset();
		}

		onReset.dispatch();
	}

	public function itemTimeChanged(item:TimelineItem):Void {
		Sure.sure(item != null);
		dirtyDuration = true;
	}

	private function removeMarked():Void {
		for (item in items) {
			if (item.markedForRemoval) {
				items.remove(item);
			}
		}
	}

	private function set_currentTime(time:Float):Float {
		return this.currentTime = FlxMath.bound(time, 0, duration);
	}

	override private function get_duration():Float {
		if (dirtyDuration) {
			var duration:Float = 0;
			for (item in items) {
				duration = Math.max(duration, item.endTime);
			}
			this.duration = duration;
			dirtyDuration = false;
		}
		return this.duration;
	}
}