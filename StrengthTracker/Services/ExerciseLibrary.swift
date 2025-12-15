import Foundation
import SwiftData

@MainActor
class ExerciseLibrary {
    static let shared = ExerciseLibrary()

    private init() {}

    func seedExercises(in context: ModelContext) {
        // Check if exercises already exist
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        print("🏋️ ExerciseLibrary: Existing exercise count = \(existingCount)")

        guard existingCount == 0 else {
            print("🏋️ ExerciseLibrary: Exercises already seeded, skipping")
            return
        }

        let exercises = createAllExercises()
        print("🏋️ ExerciseLibrary: Creating \(exercises.count) exercises")

        for exercise in exercises {
            context.insert(exercise)
        }

        do {
            try context.save()
            print("🏋️ ExerciseLibrary: Successfully saved \(exercises.count) exercises")

            // Verify the save worked
            let verifyCount = (try? context.fetchCount(descriptor)) ?? 0
            print("🏋️ ExerciseLibrary: Verification count after save = \(verifyCount)")
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
            ]
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
