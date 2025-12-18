import Foundation
import SwiftData

@MainActor
class ExerciseLibrary {
    static let shared = ExerciseLibrary()

    private init() {}

    func seedExercises(in context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingExercises = (try? context.fetch(descriptor)) ?? []
        let existingByName = Dictionary(uniqueKeysWithValues: existingExercises.map { ($0.name, $0) })

        print("🏋️ ExerciseLibrary: Existing exercise count = \(existingExercises.count)")

        let allExercises = createAllExercises()
        
        var newCount = 0
        var updatedCount = 0
        
        for exercise in allExercises {
            if let existing = existingByName[exercise.name] {
                // Update existing exercise with new data (like YouTube URLs, form cues)
                var didUpdate = false
                
                if existing.youtubeVideoURL == nil && exercise.youtubeVideoURL != nil {
                    existing.youtubeVideoURL = exercise.youtubeVideoURL
                    didUpdate = true
                }
                if existing.formCues.isEmpty && !exercise.formCues.isEmpty {
                    existing.formCuesData = exercise.formCuesData
                    didUpdate = true
                }
                if existing.commonMistakes.isEmpty && !exercise.commonMistakes.isEmpty {
                    existing.commonMistakesData = exercise.commonMistakesData
                    didUpdate = true
                }
                
                if didUpdate {
                    updatedCount += 1
                }
            } else {
                // Insert new exercise
                context.insert(exercise)
                newCount += 1
            }
        }
        
        if newCount == 0 && updatedCount == 0 {
            print("🏋️ ExerciseLibrary: All exercises up to date, skipping")
            return
        }
        
        print("🏋️ ExerciseLibrary: Adding \(newCount) new, updating \(updatedCount) existing exercises")

        do {
            try context.save()
            print("🏋️ ExerciseLibrary: Successfully saved changes")

            // Verify the save worked
            let verifyCount = (try? context.fetchCount(descriptor)) ?? 0
            print("🏋️ ExerciseLibrary: Total exercise count after save = \(verifyCount)")
        } catch {
            print("❌ ExerciseLibrary: Failed to save exercises: \(error)")
        }
    }

    private func createAllExercises() -> [Exercise] {
        var exercises: [Exercise] = []

        // MARK: - Horizontal Push (Chest)
        exercises.append(Exercise(
            name: "Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.barbell, .bench, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Retract and depress shoulder blades",
                "Maintain slight arch in lower back",
                "Plant feet firmly on floor",
                "Lower bar to mid-chest with control",
                "Drive through feet and press back to lockout"
            ],
            commonMistakes: [
                "Flaring elbows too wide (keep ~45° angle)",
                "Bouncing bar off chest",
                "Lifting hips off bench",
                "Not using leg drive"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=4Y2ZdHCOXok"
        ))

        exercises.append(Exercise(
            name: "Incline Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .frontDelt],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.barbell, .bench, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Set bench to 30-45° incline",
                "Retract shoulder blades into bench",
                "Lower bar to upper chest/clavicle area",
                "Keep wrists stacked over elbows"
            ],
            commonMistakes: [
                "Setting incline too steep (turns into shoulder press)",
                "Losing upper back tightness"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=SrqOu55lrYU"
        ))

        exercises.append(Exercise(
            name: "Dumbbell Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Start with dumbbells at shoulder level",
                "Press up and slightly in (arc motion)",
                "Lower with control to deep stretch",
                "Keep shoulder blades pinched throughout"
            ],
            commonMistakes: [
                "Going too heavy and losing control",
                "Clanking dumbbells at top",
                "Not going deep enough"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=VmB1G1K7v94"
        ))

        exercises.append(Exercise(
            name: "Incline Dumbbell Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .frontDelt],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Set bench to 30-45° incline",
                "Press up and slightly together",
                "Control the eccentric for chest stretch"
            ],
            commonMistakes: [
                "Incline too steep",
                "Rushing the negative"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=8iPEnn-ltC8"
        ))

        exercises.append(Exercise(
            name: "Floor Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .triceps],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Lie flat on floor with knees bent",
                "Lower until triceps touch floor",
                "Pause briefly, then press up",
                "Great for lockout strength"
            ],
            commonMistakes: [
                "Bouncing arms off floor",
                "Arching excessively"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=Aoyb7MlKaHc"
        ))

        exercises.append(Exercise(
            name: "Push-ups",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hands slightly wider than shoulders",
                "Body in straight line from head to heels",
                "Lower chest to just above floor",
                "Fully extend arms at top"
            ],
            commonMistakes: [
                "Sagging hips",
                "Flaring elbows out too wide",
                "Not going low enough",
                "Looking up (strain on neck)"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=IODxDxX7oi4"
        ))

        exercises.append(Exercise(
            name: "Dips",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest, .triceps],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Lean slightly forward for chest emphasis",
                "Lower until upper arms parallel to floor",
                "Keep elbows tucked (not flared)",
                "Press up to full lockout"
            ],
            commonMistakes: [
                "Going too deep (shoulder strain)",
                "Staying too upright (tricep dominant)",
                "Swinging/kipping"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=vi1-BOcj3cQ"
        ))

        exercises.append(Exercise(
            name: "Cable Fly",
            movementPattern: .isolation,
            primaryMuscles: [.chest],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Set cables at chest height",
                "Slight bend in elbows throughout",
                "Bring hands together in arc motion",
                "Squeeze chest at peak contraction"
            ],
            commonMistakes: [
                "Using too much weight",
                "Bending elbows too much (turns into press)",
                "Not controlling the stretch"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=Iwe6AmxVf7o"
        ))

        exercises.append(Exercise(
            name: "Machine Chest Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt, .triceps],
            equipmentRequired: [.machine],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Adjust seat so handles at mid-chest",
                "Press forward and squeeze",
                "Control the return"
            ],
            commonMistakes: [
                "Seat too high or low",
                "Letting weight slam back"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=xUm0BiZCWlQ"
        ))

        // MARK: - Vertical Push (Shoulders)
        exercises.append(Exercise(
            name: "Overhead Press",
            movementPattern: .verticalPush,
            primaryMuscles: [.frontDelt, .sideDelt],
            secondaryMuscles: [.triceps, .upperBack],
            equipmentRequired: [.barbell, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Start bar at front of shoulders",
                "Squeeze glutes and brace core",
                "Press straight up, moving head back",
                "Finish with bar over mid-foot",
                "Shrug at top for full lockout"
            ],
            commonMistakes: [
                "Excessive back lean",
                "Pressing forward instead of straight up",
                "Not bracing core properly"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2yjwXTZQDDI"
        ))

        exercises.append(Exercise(
            name: "Dumbbell Shoulder Press",
            movementPattern: .verticalPush,
            primaryMuscles: [.frontDelt, .sideDelt],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Sit with back supported",
                "Start dumbbells at shoulder level",
                "Press up and slightly together",
                "Lower with control"
            ],
            commonMistakes: [
                "Arching back excessively",
                "Bringing dumbbells too far forward"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=qEwKCR5JCog"
        ))

        exercises.append(Exercise(
            name: "Lateral Raise",
            movementPattern: .isolation,
            primaryMuscles: [.sideDelt],
            secondaryMuscles: [],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Slight bend in elbows",
                "Lead with elbows, not hands",
                "Raise to shoulder height",
                "Pinky slightly higher than thumb"
            ],
            commonMistakes: [
                "Using momentum/swinging",
                "Shrugging shoulders up",
                "Going too heavy"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=3VcKaXpzqRo"
        ))

        exercises.append(Exercise(
            name: "Face Pull",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt, .upperBack],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Set cable at face height",
                "Pull to face, elbows high",
                "Externally rotate at end",
                "Squeeze rear delts and upper back"
            ],
            commonMistakes: [
                "Pulling to chest instead of face",
                "Not externally rotating",
                "Using too much weight"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=rep-qVOkqgk"
        ))

        exercises.append(Exercise(
            name: "Rear Delt Fly",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt],
            secondaryMuscles: [.upperBack],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Bend at hips, chest parallel to floor",
                "Slight bend in elbows",
                "Raise arms out to sides",
                "Squeeze shoulder blades together"
            ],
            commonMistakes: [
                "Using too much weight",
                "Not hinging enough",
                "Rounding upper back"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=lPt0GqwaqEw"
        ))

        // MARK: - Horizontal Pull (Back - Rows)
        exercises.append(Exercise(
            name: "Barbell Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.rearDelt, .biceps],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Hinge at hips ~45° angle",
                "Pull bar to lower chest/upper abs",
                "Drive elbows back, squeeze lats",
                "Control the eccentric"
            ],
            commonMistakes: [
                "Standing too upright",
                "Using momentum/jerking",
                "Rounding lower back"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=FWJR5Ve8bnQ"
        ))

        exercises.append(Exercise(
            name: "Dumbbell Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.rearDelt, .biceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Support with hand and knee on bench",
                "Keep back flat and parallel to floor",
                "Pull dumbbell to hip",
                "Full stretch at bottom"
            ],
            commonMistakes: [
                "Rotating torso",
                "Not getting full stretch",
                "Pulling to chest instead of hip"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=pYcpY20QaE8"
        ))

        exercises.append(Exercise(
            name: "Chest Supported Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.rearDelt, .biceps],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Lie face down on incline bench",
                "Let arms hang straight down",
                "Row dumbbells to sides of bench",
                "Squeeze shoulder blades together"
            ],
            commonMistakes: [
                "Bench angle too steep",
                "Not achieving full stretch"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=H75im9fAUMc"
        ))

        exercises.append(Exercise(
            name: "Cable Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.cable],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Sit with slight knee bend",
                "Pull handle to lower chest",
                "Squeeze shoulder blades",
                "Control the stretch forward"
            ],
            commonMistakes: [
                "Using too much body lean",
                "Rounding back on stretch"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=GZbfZ033f74"
        ))

        exercises.append(Exercise(
            name: "Inverted Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.bodyweight, .pullUpBar],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Body in straight line",
                "Pull chest to bar",
                "Squeeze shoulder blades at top",
                "Lower with control"
            ],
            commonMistakes: [
                "Sagging hips",
                "Not pulling high enough"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=hXTc1mDnZCw"
        ))

        // MARK: - Vertical Pull (Back - Pulldowns/Pull-ups)
        exercises.append(Exercise(
            name: "Pull-ups",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats, .upperBack],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.pullUpBar],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Grip slightly wider than shoulders",
                "Initiate by depressing shoulder blades",
                "Pull chest to bar",
                "Full hang at bottom (dead hang)"
            ],
            commonMistakes: [
                "Kipping/swinging",
                "Not going to full hang",
                "Only pulling chin to bar level"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=eGo4IYlbE5g"
        ))

        exercises.append(Exercise(
            name: "Chin-ups",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats, .biceps],
            secondaryMuscles: [.upperBack],
            equipmentRequired: [.pullUpBar],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Underhand grip, shoulder width",
                "Pull until chin clears bar",
                "Squeeze biceps at top",
                "Control the descent"
            ],
            commonMistakes: [
                "Half reps",
                "Excessive swinging"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=brhRXlOhsAM"
        ))

        exercises.append(Exercise(
            name: "Lat Pulldown",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats],
            secondaryMuscles: [.upperBack, .biceps],
            equipmentRequired: [.cable],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Lean back slightly",
                "Pull bar to upper chest",
                "Drive elbows down and back",
                "Full stretch at top"
            ],
            commonMistakes: [
                "Leaning too far back",
                "Pulling behind neck (injury risk)",
                "Using momentum"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=CAwf7n6Luuc"
        ))

        exercises.append(Exercise(
            name: "Banded Pull-ups",
            movementPattern: .verticalPull,
            primaryMuscles: [.lats, .upperBack],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.pullUpBar, .bands],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Loop band around bar and under foot/knee",
                "Same form as regular pull-ups",
                "Progress to lighter bands over time"
            ],
            commonMistakes: [
                "Relying too much on band assistance",
                "Not progressing to less assistance"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=Y3ntNsIS2Q8"
        ))

        // MARK: - Squat Pattern (Quads)
        exercises.append(Exercise(
            name: "Barbell Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipmentRequired: [.barbell, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Bar on upper back (high bar) or rear delts (low bar)",
                "Feet shoulder width, toes slightly out",
                "Brace core, take breath at top",
                "Break at hips and knees simultaneously",
                "Depth: hip crease below knee",
                "Drive through whole foot to stand"
            ],
            commonMistakes: [
                "Knees caving inward",
                "Heels rising off floor",
                "Butt wink at bottom",
                "Good morning-ing the weight up"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=bEv6CCg2BC8"
        ))

        exercises.append(Exercise(
            name: "Front Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes, .core],
            equipmentRequired: [.barbell, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Bar rests on front delts",
                "Elbows high, upper arms parallel to floor",
                "Stay more upright than back squat",
                "Knees track over toes"
            ],
            commonMistakes: [
                "Elbows dropping",
                "Leaning too far forward",
                "Wrist pain (work on mobility)"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=m4ytaCJZpl0"
        ))

        exercises.append(Exercise(
            name: "Goblet Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.core],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hold dumbbell at chest, elbows tucked",
                "Feet shoulder width apart",
                "Squat between legs",
                "Keep chest tall throughout"
            ],
            commonMistakes: [
                "Leaning forward",
                "Knees caving in"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=MeIiIdhvXT4"
        ))

        exercises.append(Exercise(
            name: "Leg Press",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Feet hip to shoulder width on platform",
                "Lower until knees at ~90°",
                "Keep lower back on pad",
                "Don't lock out knees completely"
            ],
            commonMistakes: [
                "Feet too high (more glute) or low (more quad)",
                "Going too deep and rounding lower back",
                "Locking knees aggressively"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=IZxyjW7MPJQ"
        ))

        exercises.append(Exercise(
            name: "Hack Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.machine],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Shoulders under pads, back flat",
                "Feet low and narrow for more quad",
                "Controlled descent",
                "Drive through heels"
            ],
            commonMistakes: [
                "Knees caving",
                "Heels rising"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=0tn5K9NlCfo"
        ))

        exercises.append(Exercise(
            name: "Leg Extension",
            movementPattern: .isolation,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Adjust pad to rest on lower shins",
                "Extend until legs straight",
                "Squeeze quads at top",
                "Control the descent"
            ],
            commonMistakes: [
                "Using momentum",
                "Not achieving full contraction"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=YyvSfVjQeL0"
        ))

        // MARK: - Hinge Pattern (Hamstrings/Glutes)
        exercises.append(Exercise(
            name: "Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes, .lowerBack],
            secondaryMuscles: [.quads, .upperBack, .traps],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Bar over mid-foot, shoulder width stance",
                "Grip just outside legs",
                "Chest up, back flat, lats engaged",
                "Push floor away, bar drags up legs",
                "Hips and shoulders rise together",
                "Lock out with glutes, don't hyperextend"
            ],
            commonMistakes: [
                "Rounding lower back",
                "Bar drifting forward",
                "Hips shooting up first",
                "Hyperextending at lockout"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=op9kVnSso6Q"
        ))

        exercises.append(Exercise(
            name: "Romanian Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Start standing, slight knee bend",
                "Push hips back, bar slides down thighs",
                "Lower until hamstring stretch (not floor)",
                "Drive hips forward to stand"
            ],
            commonMistakes: [
                "Bending knees too much (becomes squat)",
                "Rounding back",
                "Going too low"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=JCXUYuzwNrM"
        ))

        exercises.append(Exercise(
            name: "Dumbbell Romanian Deadlift",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Dumbbells in front of thighs",
                "Push hips back with soft knees",
                "Feel hamstring stretch",
                "Squeeze glutes at top"
            ],
            commonMistakes: [
                "Dumbbells too far from body",
                "Rounding back"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=hCDzSR6bW10"
        ))

        exercises.append(Exercise(
            name: "Leg Curl",
            movementPattern: .isolation,
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Pad above heels/on Achilles",
                "Curl until full contraction",
                "Control the negative slowly",
                "Don't lift hips off pad"
            ],
            commonMistakes: [
                "Using momentum",
                "Hips coming up"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=1Tq3QdYUuHs"
        ))

        // MARK: - Lunge Pattern
        exercises.append(Exercise(
            name: "Bulgarian Split Squat",
            movementPattern: .lunge,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [.dumbbell, .bench],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Rear foot on bench, laces down",
                "Front foot ~2 feet from bench",
                "Lower until back knee near floor",
                "Keep torso upright",
                "Drive through front heel"
            ],
            commonMistakes: [
                "Front foot too close to bench",
                "Leaning too far forward",
                "Knee caving inward"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2C-uNgKwPLE"
        ))

        exercises.append(Exercise(
            name: "Walking Lunges",
            movementPattern: .lunge,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Step forward with long stride",
                "Lower until back knee near floor",
                "Push off front foot to next step",
                "Keep torso upright"
            ],
            commonMistakes: [
                "Steps too short",
                "Leaning forward",
                "Losing balance"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=L8fvypPrzzs"
        ))

        // MARK: - Arms (Biceps)
        exercises.append(Exercise(
            name: "Barbell Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipmentRequired: [.barbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Grip shoulder width",
                "Elbows pinned to sides",
                "Curl with biceps, not momentum",
                "Squeeze at top, control descent"
            ],
            commonMistakes: [
                "Swinging/using momentum",
                "Elbows drifting forward",
                "Incomplete range of motion"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=kwG2ipFRgfo"
        ))

        exercises.append(Exercise(
            name: "Dumbbell Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [.forearms],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Start with palms forward or neutral",
                "Curl to shoulder, squeeze bicep",
                "Supinate (turn palm up) during curl",
                "Control the negative"
            ],
            commonMistakes: [
                "Swinging dumbbells",
                "Not supinating fully"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=ykJmrZ5v0Oo"
        ))

        exercises.append(Exercise(
            name: "Cable Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Constant tension throughout",
                "Elbows at sides",
                "Full range of motion"
            ],
            commonMistakes: [
                "Using body momentum"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=NFzTWp2qpiE"
        ))

        exercises.append(Exercise(
            name: "Band Curl",
            movementPattern: .isolation,
            primaryMuscles: [.biceps],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Stand on band, grip handles",
                "Curl against increasing resistance",
                "Peak contraction at top"
            ],
            commonMistakes: [
                "Using momentum"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=4POPGq4poXo"
        ))

        // MARK: - Arms (Triceps)
        exercises.append(Exercise(
            name: "Tricep Pushdown",
            movementPattern: .isolation,
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Elbows at sides, fixed position",
                "Push down until arms straight",
                "Squeeze triceps at bottom",
                "Control return"
            ],
            commonMistakes: [
                "Elbows flaring",
                "Leaning into movement",
                "Not achieving full lockout"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2-LAMcpzODU"
        ))

        exercises.append(Exercise(
            name: "Overhead Tricep Extension",
            movementPattern: .isolation,
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipmentRequired: [.dumbbell],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hold dumbbell overhead with both hands",
                "Lower behind head, elbows pointing up",
                "Extend to full lockout",
                "Keep elbows close to head"
            ],
            commonMistakes: [
                "Elbows flaring out",
                "Not going low enough"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=YbX7Wd8jQ-Q"
        ))

        exercises.append(Exercise(
            name: "Close Grip Bench Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.triceps, .chest],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.barbell, .bench, .rack],
            isCompound: true,
            defaultProgressionType: .topSetBackoff,
            formCues: [
                "Grip shoulder width or slightly narrower",
                "Elbows tucked close to body",
                "Lower to lower chest",
                "Press up focusing on triceps"
            ],
            commonMistakes: [
                "Grip too narrow (wrist strain)",
                "Flaring elbows"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=nEF0bv2FW94"
        ))

        exercises.append(Exercise(
            name: "Diamond Push-ups",
            movementPattern: .horizontalPush,
            primaryMuscles: [.triceps],
            secondaryMuscles: [.chest],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hands together forming diamond shape",
                "Lower chest toward hands",
                "Keep body straight",
                "Full extension at top"
            ],
            commonMistakes: [
                "Hips sagging",
                "Elbows flaring wide"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=J0DnG1_S92I"
        ))

        // MARK: - Calves
        exercises.append(Exercise(
            name: "Standing Calf Raise",
            movementPattern: .isolation,
            primaryMuscles: [.calves],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Balls of feet on platform",
                "Lower heels for full stretch",
                "Rise up on toes, squeeze at top",
                "Straight legs throughout"
            ],
            commonMistakes: [
                "Bouncing",
                "Not achieving full range",
                "Bending knees"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=-M4-G8p8fmc"
        ))

        exercises.append(Exercise(
            name: "Seated Calf Raise",
            movementPattern: .isolation,
            primaryMuscles: [.calves],
            secondaryMuscles: [],
            equipmentRequired: [.machine],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Knees under pad",
                "Balls of feet on platform",
                "Full stretch, then press up",
                "Targets soleus muscle"
            ],
            commonMistakes: [
                "Limited range of motion"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=JbyjNymZOt0"
        ))

        // MARK: - Core
        exercises.append(Exercise(
            name: "Plank",
            movementPattern: .isolation,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Forearms on ground, elbows under shoulders",
                "Body in straight line",
                "Squeeze glutes and brace abs",
                "Don't let hips sag or pike"
            ],
            commonMistakes: [
                "Hips too high or low",
                "Holding breath",
                "Looking up (neck strain)"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=pSHjTRCQxIw"
        ))

        exercises.append(Exercise(
            name: "Cable Crunch",
            movementPattern: .isolation,
            primaryMuscles: [.core],
            secondaryMuscles: [],
            equipmentRequired: [.cable],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Kneel facing cable, rope behind head",
                "Crunch down bringing elbows to thighs",
                "Focus on contracting abs",
                "Control return"
            ],
            commonMistakes: [
                "Using hip flexors",
                "Pulling with arms"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2fbujeH3F0E"
        ))
        
        // MARK: - Kettlebell Exercises
        exercises.append(Exercise(
            name: "Kettlebell Swing",
            movementPattern: .hinge,
            primaryMuscles: [.glutes, .hamstrings],
            secondaryMuscles: [.core, .lowerBack],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hinge at hips, not squat down",
                "Swing bell between legs like hiking football",
                "Snap hips forward explosively",
                "Arms are just hooks - power from hips",
                "Bell should float to chest height"
            ],
            commonMistakes: [
                "Squatting instead of hinging",
                "Using arms to lift bell",
                "Hyperextending back at top",
                "Not engaging glutes at top"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=YSxHifyI6s8"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Goblet Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.core],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hold bell at chest, elbows inside knees",
                "Squat between legs",
                "Use elbows to push knees out",
                "Keep chest tall"
            ],
            commonMistakes: [
                "Letting elbows float away from body",
                "Knees caving in"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=MeIiIdhvXT4"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Turkish Get-Up",
            movementPattern: .carry,
            primaryMuscles: [.core],
            secondaryMuscles: [.glutes, .frontDelt, .quads],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Start lying down, bell pressed up",
                "Roll to elbow, then to hand",
                "Bridge hips up high",
                "Sweep leg through to kneeling",
                "Stand up keeping bell overhead",
                "Reverse steps to return"
            ],
            commonMistakes: [
                "Rushing through steps",
                "Letting bell drift forward",
                "Not keeping eyes on bell"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=0bWRPC6gdPg"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Clean",
            movementPattern: .hinge,
            primaryMuscles: [.glutes, .hamstrings],
            secondaryMuscles: [.forearms, .core],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Similar to swing but pull bell to rack position",
                "Insert hand around bell, don't flip it",
                "Bell should land softly in rack",
                "Elbow tight to body in rack"
            ],
            commonMistakes: [
                "Bell banging wrist/forearm",
                "Muscling it up instead of using hips"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=mKDIuUbH94Q"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Press",
            movementPattern: .verticalPush,
            primaryMuscles: [.frontDelt, .sideDelt],
            secondaryMuscles: [.triceps, .core],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Start in rack position",
                "Press straight up, rotating wrist",
                "Lockout with bell behind wrist",
                "Control descent back to rack"
            ],
            commonMistakes: [
                "Excessive back lean",
                "Bell drifting forward"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=H2GHXHS_Wvw"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Snatch",
            movementPattern: .hinge,
            primaryMuscles: [.glutes, .hamstrings, .frontDelt],
            secondaryMuscles: [.core, .traps],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Explosive hip snap like swing",
                "Pull bell high, punch through at top",
                "Bell should arc over and land softly",
                "Control descent through backswing"
            ],
            commonMistakes: [
                "Bell flipping and banging wrist",
                "Using too much arm",
                "Not punching through at top"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=XS8RfLfioKk"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Row",
            movementPattern: .horizontalPull,
            primaryMuscles: [.upperBack, .lats],
            secondaryMuscles: [.biceps],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Hinge at hips or use bench support",
                "Pull bell to hip/lower ribs",
                "Squeeze shoulder blade back",
                "Control the descent"
            ],
            commonMistakes: [
                "Rotating torso",
                "Shrugging shoulder"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2tnlrTnh7BE"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Farmer Carry",
            movementPattern: .carry,
            primaryMuscles: [.traps, .forearms, .core],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Hold bells at sides, stand tall",
                "Shoulders back and down",
                "Walk with controlled steps",
                "Brace core throughout"
            ],
            commonMistakes: [
                "Hunching shoulders",
                "Leaning to one side"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=Fkzk_RqlYig"
        ))
        
        // MARK: - Additional Carry Exercises
        exercises.append(Exercise(
            name: "Dumbbell Farmer Walk",
            movementPattern: .carry,
            primaryMuscles: [.traps, .forearms, .core],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Hold dumbbells at sides with neutral grip",
                "Stand tall, shoulders back and down",
                "Walk with short, controlled steps",
                "Brace core, don't let weights swing"
            ],
            commonMistakes: [
                "Letting weights swing",
                "Hunching shoulders up",
                "Taking too long of strides"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=Fkzk_RqlYig"
        ))
        
        exercises.append(Exercise(
            name: "Suitcase Carry",
            movementPattern: .carry,
            primaryMuscles: [.core],
            secondaryMuscles: [.traps, .forearms],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Hold single dumbbell/kettlebell at one side",
                "Stay perfectly upright - no leaning",
                "Brace obliques to resist lateral flexion",
                "Walk with controlled steps"
            ],
            commonMistakes: [
                "Leaning away from weight",
                "Letting hip drop on loaded side",
                "Shrugging shoulder"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=qldiMxNdqfM"
        ))
        
        exercises.append(Exercise(
            name: "Overhead Carry",
            movementPattern: .carry,
            primaryMuscles: [.frontDelt, .sideDelt, .core],
            secondaryMuscles: [.triceps, .traps],
            equipmentRequired: [.dumbbell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Press weight(s) overhead, lock out arms",
                "Keep ribs down, don't arch back",
                "Engage core and walk slowly",
                "Keep biceps by ears"
            ],
            commonMistakes: [
                "Arching lower back",
                "Letting arms drift forward",
                "Walking too fast"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=xCRCLyQYXLo"
        ))
        
        exercises.append(Exercise(
            name: "Rack Carry",
            movementPattern: .carry,
            primaryMuscles: [.core, .biceps],
            secondaryMuscles: [.forearms, .frontDelt],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Clean kettlebells to rack position",
                "Elbows tight to body",
                "Stay tall through torso",
                "Walk with controlled steps"
            ],
            commonMistakes: [
                "Letting elbows flare out",
                "Rounding upper back",
                "Holding breath"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=cN8JN0dS5uk"
        ))
        
        exercises.append(Exercise(
            name: "Trap Bar Carry",
            movementPattern: .carry,
            primaryMuscles: [.traps, .forearms, .core],
            secondaryMuscles: [.glutes, .quads],
            equipmentRequired: [.barbell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Deadlift trap bar to standing",
                "Stand tall, chest up",
                "Walk with small, controlled steps",
                "Keep weight balanced"
            ],
            commonMistakes: [
                "Rounding back",
                "Taking too large steps",
                "Looking down"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=F-VIfHe4T3M"
        ))
        
        exercises.append(Exercise(
            name: "Waiter Carry",
            movementPattern: .carry,
            primaryMuscles: [.frontDelt, .sideDelt, .core],
            secondaryMuscles: [.triceps],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Hold kettlebell bottoms-up overhead",
                "Wrist straight, grip tight",
                "Walk slowly and controlled",
                "Keep shoulder packed and stable"
            ],
            commonMistakes: [
                "Letting wrist bend back",
                "Walking too fast",
                "Not engaging shoulder stability"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=QwVZPGKePag"
        ))
        
        exercises.append(Exercise(
            name: "Kettlebell Windmill",
            movementPattern: .mobility,
            primaryMuscles: [.core],
            secondaryMuscles: [.hamstrings, .glutes],
            equipmentRequired: [.kettlebell],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Press bell overhead, turn feet out 45°",
                "Push hip out to bell side",
                "Slide opposite hand down leg",
                "Keep eyes on bell throughout",
                "Maintain straight arm overhead"
            ],
            commonMistakes: [
                "Bending the overhead arm",
                "Not keeping eyes on bell",
                "Rushing the movement"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=sGspFB8kPD0"
        ))
        
        // MARK: - Additional Band Exercises
        exercises.append(Exercise(
            name: "Band Pull-Apart",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt, .upperBack],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Hold band at shoulder width",
                "Arms straight out in front",
                "Pull band apart to chest",
                "Squeeze shoulder blades together"
            ],
            commonMistakes: [
                "Bending elbows",
                "Shrugging shoulders"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=8lDC4Ri9zAQ"
        ))
        
        exercises.append(Exercise(
            name: "Band Face Pull",
            movementPattern: .isolation,
            primaryMuscles: [.rearDelt, .upperBack],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Anchor band at face height",
                "Pull to face, elbows high",
                "Externally rotate at end",
                "Squeeze rear delts"
            ],
            commonMistakes: [
                "Pulling to chest instead of face"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=0Po47vvj9g4"
        ))
        
        exercises.append(Exercise(
            name: "Band Tricep Extension",
            movementPattern: .isolation,
            primaryMuscles: [.triceps],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Anchor band high, face away",
                "Elbows at sides",
                "Extend arms fully",
                "Squeeze triceps at bottom"
            ],
            commonMistakes: [
                "Elbows moving"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2QeojELM4K0"
        ))
        
        exercises.append(Exercise(
            name: "Band Lateral Raise",
            movementPattern: .isolation,
            primaryMuscles: [.sideDelt],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: false,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Stand on band, hold ends",
                "Raise arms to shoulder height",
                "Lead with elbows",
                "Control descent"
            ],
            commonMistakes: [
                "Shrugging"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=Sl9RKnV9B9g"
        ))
        
        exercises.append(Exercise(
            name: "Band Squat",
            movementPattern: .squat,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [],
            equipmentRequired: [.bands],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Stand on band, hold at shoulders",
                "Squat with band adding resistance",
                "Drive up against band tension"
            ],
            commonMistakes: [
                "Band slipping"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=ZZH5MNmC4OE"
        ))
        
        exercises.append(Exercise(
            name: "Band Good Morning",
            movementPattern: .hinge,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.bands],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Band around neck/shoulders, stand on band",
                "Hinge at hips with soft knees",
                "Feel hamstring stretch",
                "Drive hips forward to stand"
            ],
            commonMistakes: [
                "Rounding back"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=7GGKTQVJYCY"
        ))
        
        exercises.append(Exercise(
            name: "Band Chest Press",
            movementPattern: .horizontalPush,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .frontDelt],
            equipmentRequired: [.bands],
            isCompound: true,
            defaultProgressionType: .doubleProgression,
            formCues: [
                "Band around upper back",
                "Press forward like bench press",
                "Squeeze chest at extension"
            ],
            commonMistakes: [
                "Band too loose"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=I8CU5pT9xaE"
        ))
        
        // MARK: - Cardio Exercises
        exercises.append(Exercise(
            name: "Treadmill Running",
            movementPattern: .cardio,
            primaryMuscles: [.quads, .hamstrings, .calves],
            secondaryMuscles: [.core, .glutes],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Land mid-foot, not heel",
                "Quick cadence ~170-180 steps/min",
                "Arms swing naturally",
                "Slight forward lean from ankles"
            ],
            commonMistakes: [
                "Overstriding (landing ahead of body)",
                "Holding handrails",
                "Tense shoulders"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=brFHyOtTwH4",
            durationSeconds: 1800
        ))

        exercises.append(Exercise(
            name: "Treadmill Incline Walk",
            movementPattern: .cardio,
            primaryMuscles: [.glutes, .hamstrings, .calves],
            secondaryMuscles: [.quads],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Set incline 10-15%",
                "Walk at moderate pace",
                "Don't hold handrails",
                "Engage glutes with each step"
            ],
            commonMistakes: [
                "Holding handrails (defeats purpose)",
                "Leaning forward"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=nnkyDp7AioM",
            durationSeconds: 1800
        ))

        exercises.append(Exercise(
            name: "Stationary Bike",
            movementPattern: .cardio,
            primaryMuscles: [.quads, .hamstrings],
            secondaryMuscles: [.calves, .glutes],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Adjust seat height (slight knee bend at bottom)",
                "Push and pull through pedal stroke",
                "Maintain steady cadence"
            ],
            commonMistakes: [
                "Seat too low or high",
                "Bouncing in saddle"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2oLc8mc87A8",
            durationSeconds: 1800
        ))

        exercises.append(Exercise(
            name: "Rowing Machine",
            movementPattern: .cardio,
            primaryMuscles: [.lats, .upperBack, .quads],
            secondaryMuscles: [.biceps, .hamstrings, .core],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Drive with legs first",
                "Lean back slightly, then pull handle to chest",
                "Return: arms, body lean, then legs",
                "Maintain rhythm"
            ],
            commonMistakes: [
                "Pulling with arms before legs extend",
                "Hunching over",
                "Hyperextending back"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=H0r3oCWYq1c",
            durationSeconds: 1200
        ))

        exercises.append(Exercise(
            name: "Stair Climber",
            movementPattern: .cardio,
            primaryMuscles: [.glutes, .quads],
            secondaryMuscles: [.hamstrings, .calves],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Stand upright, light touch on rails",
                "Push through whole foot",
                "Controlled step pace",
                "Engage glutes each step"
            ],
            commonMistakes: [
                "Leaning heavily on rails",
                "Taking tiny steps"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=j9U9M5PRljs",
            durationSeconds: 1200
        ))

        exercises.append(Exercise(
            name: "Elliptical",
            movementPattern: .cardio,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.hamstrings, .core],
            equipmentRequired: [.cardioMachine],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Push and pull with arms and legs",
                "Keep core engaged",
                "Stand upright"
            ],
            commonMistakes: [
                "Just going through motions",
                "Leaning forward"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=4Rxh8-wM_LA",
            durationSeconds: 1800
        ))

        exercises.append(Exercise(
            name: "Battle Ropes",
            movementPattern: .cardio,
            primaryMuscles: [.frontDelt, .core],
            secondaryMuscles: [.biceps, .forearms, .lats],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Athletic stance, knees slightly bent",
                "Create alternating waves",
                "Keep waves going to anchor",
                "Core braced throughout"
            ],
            commonMistakes: [
                "Standing too upright",
                "Small amplitude waves"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=bi6-cwwf5sA",
            durationSeconds: 60
        ))
        
        exercises.append(Exercise(
            name: "Jump Rope",
            movementPattern: .cardio,
            primaryMuscles: [.calves],
            secondaryMuscles: [.quads, .core, .forearms],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Bounce on balls of feet",
                "Small jumps, just clearing rope",
                "Wrists do the work, not arms",
                "Keep elbows close to sides"
            ],
            commonMistakes: [
                "Jumping too high",
                "Using arms too much",
                "Landing flat-footed"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=u3zgHI8QnqE",
            durationSeconds: 300
        ))
        
        exercises.append(Exercise(
            name: "Box Jumps",
            movementPattern: .cardio,
            primaryMuscles: [.quads, .glutes],
            secondaryMuscles: [.calves, .hamstrings],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Start in athletic stance",
                "Swing arms and explode up",
                "Land softly with both feet",
                "Step down (don't jump down repeatedly)"
            ],
            commonMistakes: [
                "Landing hard",
                "Jumping down (Achilles stress)",
                "Box too high for skill level"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=52r_Ul5k03g"
        ))

        exercises.append(Exercise(
            name: "Burpees",
            movementPattern: .cardio,
            primaryMuscles: [.quads, .chest, .core],
            secondaryMuscles: [.triceps, .frontDelt],
            equipmentRequired: [.bodyweight],
            isCompound: true,
            defaultProgressionType: .straightSets,
            formCues: [
                "Drop to floor, chest touches",
                "Push up and jump feet to hands",
                "Explode up with jump and arm reach",
                "Land softly and repeat"
            ],
            commonMistakes: [
                "Skipping the chest-to-floor",
                "Landing hard on jump"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=auBLPXO8Fww"
        ))

        // MARK: - Pre-Workout Mobility Routines
        exercises.append(Exercise(
            name: "Cat-Cow Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.core],
            secondaryMuscles: [.lowerBack],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Start on hands and knees",
                "Arch back up (cat), head down",
                "Then drop belly, head up (cow)",
                "Flow between positions with breath"
            ],
            commonMistakes: [
                "Rushing through",
                "Not coordinating with breath"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=kqnua4rHVVA",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        ))

        exercises.append(Exercise(
            name: "World's Greatest Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.glutes, .hamstrings],
            secondaryMuscles: [.core, .quads],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Lunge forward with left leg",
                "Place both hands inside left foot",
                "Rotate left arm to ceiling",
                "Return and repeat other side"
            ],
            commonMistakes: [
                "Not opening up rotation enough",
                "Rushing"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=JYKakSAQwNM",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 90
        ))

        exercises.append(Exercise(
            name: "Hip Circles",
            movementPattern: .mobility,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.core],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Stand on one leg",
                "Make large circles with raised knee",
                "Both directions",
                "Keep standing leg stable"
            ],
            commonMistakes: [
                "Circles too small",
                "Losing balance"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=3eV7IcfX1QA",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        ))

        exercises.append(Exercise(
            name: "Arm Circles",
            movementPattern: .mobility,
            primaryMuscles: [.frontDelt, .sideDelt],
            secondaryMuscles: [.upperBack],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Arms out to sides",
                "Small circles, gradually bigger",
                "Forward and backward",
                "Keep core engaged"
            ],
            commonMistakes: [
                "Shrugging shoulders"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=140RTNMciH8",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 45
        ))

        exercises.append(Exercise(
            name: "Leg Swings",
            movementPattern: .mobility,
            primaryMuscles: [.hamstrings, .quads],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Hold wall for support",
                "Swing leg forward and back",
                "Increase range gradually",
                "Keep standing leg stable"
            ],
            commonMistakes: [
                "Swinging too aggressively at start"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=lOCse3urMFA",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        ))

        exercises.append(Exercise(
            name: "Thoracic Rotation",
            movementPattern: .mobility,
            primaryMuscles: [.upperBack],
            secondaryMuscles: [.core],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "On all fours, hand behind head",
                "Rotate elbow to ceiling",
                "Follow elbow with eyes",
                "Keep hips square"
            ],
            commonMistakes: [
                "Moving hips instead of thoracic spine"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=aJjFjb8R_W0",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        ))
        
        exercises.append(Exercise(
            name: "Squat to Stand",
            movementPattern: .mobility,
            primaryMuscles: [.hamstrings, .glutes],
            secondaryMuscles: [.quads, .lowerBack],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Stand with feet hip width",
                "Bend forward and grab toes",
                "Lower into deep squat, chest up",
                "Straighten legs, keeping hands on toes",
                "Repeat flow"
            ],
            commonMistakes: [
                "Rounding back when standing"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=NwqVPt0xhYQ",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        ))
        
        exercises.append(Exercise(
            name: "Inchworm",
            movementPattern: .mobility,
            primaryMuscles: [.hamstrings, .core],
            secondaryMuscles: [.frontDelt, .chest],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Stand tall, bend and touch floor",
                "Walk hands out to plank",
                "Walk feet to hands",
                "Stand and repeat"
            ],
            commonMistakes: [
                "Bending knees too much"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=ZY2ji_Ho0dA",
            isMobilityRoutine: true,
            routineType: "pre-workout",
            durationSeconds: 60
        ))
        
        // MARK: - Post-Workout Mobility/Stretching
        exercises.append(Exercise(
            name: "Pigeon Pose",
            movementPattern: .mobility,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Front shin angled across mat",
                "Back leg extended straight behind",
                "Sink hips toward floor",
                "Hold and breathe deeply"
            ],
            commonMistakes: [
                "Forcing depth",
                "Not keeping hips square"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=8x0TDdQrFEg",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 90
        ))
        
        exercises.append(Exercise(
            name: "Couch Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.quads],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Back knee against wall/couch",
                "Front foot flat on ground",
                "Squeeze glute of back leg",
                "Stay upright, don't lean forward"
            ],
            commonMistakes: [
                "Excessive forward lean",
                "Not squeezing glute"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=6CKXKDkEDSc",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 90
        ))
        
        exercises.append(Exercise(
            name: "90/90 Hip Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.glutes],
            secondaryMuscles: [.hamstrings],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Sit with both legs at 90° angles",
                "Front shin parallel to body",
                "Back shin perpendicular to body",
                "Lean forward over front leg"
            ],
            commonMistakes: [
                "Lifting back hip off floor"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=fQQvMhLRMBQ",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 90
        ))
        
        exercises.append(Exercise(
            name: "Standing Hamstring Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.hamstrings],
            secondaryMuscles: [],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Place heel on elevated surface",
                "Keep standing leg straight",
                "Hinge at hips, reach toward toes",
                "Feel stretch in hamstring"
            ],
            commonMistakes: [
                "Rounding back instead of hinging"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=_NxAaYiMwOU",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 60
        ))
        
        exercises.append(Exercise(
            name: "Chest Doorway Stretch",
            movementPattern: .mobility,
            primaryMuscles: [.chest],
            secondaryMuscles: [.frontDelt],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Forearm on door frame, elbow at shoulder height",
                "Step through doorway",
                "Feel stretch across chest",
                "Hold and breathe"
            ],
            commonMistakes: [
                "Elbow too high or low",
                "Rotating torso"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=SLLi7A1pOt4",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 60
        ))
        
        exercises.append(Exercise(
            name: "Child's Pose",
            movementPattern: .mobility,
            primaryMuscles: [.lowerBack, .lats],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Kneel on floor, big toes together",
                "Sit back on heels",
                "Reach arms forward on floor",
                "Relax and breathe into back"
            ],
            commonMistakes: [
                "Not relaxing fully"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=2MJGg-dUKh0",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 60
        ))
        
        exercises.append(Exercise(
            name: "Foam Roll Quads",
            movementPattern: .mobility,
            primaryMuscles: [.quads],
            secondaryMuscles: [],
            equipmentRequired: [.foamRoller],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Face down, roller under thighs",
                "Roll from hip to just above knee",
                "Pause on tender spots",
                "Rotate to hit all areas"
            ],
            commonMistakes: [
                "Rolling too fast",
                "Rolling over knee"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=8kVYBsADMa4",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 120
        ))
        
        exercises.append(Exercise(
            name: "Foam Roll Lats",
            movementPattern: .mobility,
            primaryMuscles: [.lats],
            secondaryMuscles: [.upperBack],
            equipmentRequired: [.foamRoller],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Lie on side, roller under armpit",
                "Arm extended overhead",
                "Roll from armpit to mid-ribcage",
                "Pause on tender spots"
            ],
            commonMistakes: [
                "Rolling too fast"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=QBXkKWmKcA0",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 90
        ))
        
        exercises.append(Exercise(
            name: "Foam Roll Upper Back",
            movementPattern: .mobility,
            primaryMuscles: [.upperBack],
            secondaryMuscles: [],
            equipmentRequired: [.foamRoller],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Roller under upper back",
                "Arms crossed over chest",
                "Lift hips and roll up and down",
                "Extend over roller for mobility"
            ],
            commonMistakes: [
                "Rolling too low onto lower back",
                "Neck straining"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=dZrBHNvxqBs",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 120
        ))
        
        exercises.append(Exercise(
            name: "Lying Spinal Twist",
            movementPattern: .mobility,
            primaryMuscles: [.lowerBack],
            secondaryMuscles: [.glutes],
            equipmentRequired: [.bodyweight],
            isCompound: false,
            defaultProgressionType: .straightSets,
            formCues: [
                "Lie on back, arms out",
                "Bring one knee across body",
                "Keep shoulders on floor",
                "Look opposite direction of knee"
            ],
            commonMistakes: [
                "Shoulder lifting off floor"
            ],
            youtubeVideoURL: "https://www.youtube.com/watch?v=VNWmAwBLVkM",
            isMobilityRoutine: true,
            routineType: "post-workout",
            durationSeconds: 60
        ))

        return exercises
    }

    func getExercise(named name: String, from context: ModelContext) -> Exercise? {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.name == name }
        )
        return try? context.fetch(descriptor).first
    }

    func getExercises(for pattern: MovementPattern, from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.movementPattern == pattern }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getExercises(targeting muscle: Muscle, from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.primaryMuscles.contains(muscle) || $0.secondaryMuscles.contains(muscle) }
    }

    func getAvailableExercises(for equipment: Set<Equipment>, from context: ModelContext) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>()
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { exercise in
            Set(exercise.equipmentRequired).isSubset(of: equipment)
        }
    }
}
