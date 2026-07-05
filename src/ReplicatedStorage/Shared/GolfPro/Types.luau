--!strict

export type Surface = "tee" | "fairway" | "rough" | "green" | "bunker" | "water" | "out_of_bounds"

export type ShotType = "normal" | "punch" | "flop" | "chip" | "putt"

export type Vector2Yards = {
	x: number,
	y: number,
}

export type Bounds2Yards = {
	minX: number,
	maxX: number,
	minY: number,
	maxY: number,
}

export type ClubSpec = {
	id: string,
	displayName: string,
	category: string,
	maxCarryYards: number,
	minCarryYards: number,
	loftDeg: number,
	baseDispersionYards: number,
	mishitPenalty: number,
	spinBias: number,
	rollBias: number,
	allowedShotTypes: { ShotType },
	rankedStatProfile: string,
}

export type SurfaceZone = {
	id: string,
	surface: Surface,
	priority: number,
	bounds: Bounds2Yards,
}

export type HoleSpec = {
	index: number,
	name: string,
	par: number,
	yardage: number,
	tee: Vector2Yards,
	pin: Vector2Yards,
	zones: { SurfaceZone },
}

export type CourseSpec = {
	id: string,
	displayName: string,
	version: string,
	category: string,
	physicsVersion: string,
	teeSets: { string },
	pinSets: { string },
	rankedEnabled: boolean,
	record: nil | {
		playerUserId: number,
		score: number,
		roundId: string,
		setAtUnix: number,
	},
	legal: {
		category: string,
		approvedNameUsage: boolean,
		approvedLayoutUsage: boolean,
		approvedImageryUsage: boolean,
		sourceNotes: string,
	},
	holes: { HoleSpec },
}

export type ShotIntent = {
	roundId: string,
	holeIndex: number,
	playerUserId: number,
	clubId: string,
	shotType: ShotType,
	aimYawDeg: number,
	aimPitchDeg: number,
	power01: number,
	accuracy01: number,
	spin01: number,
	drawFade01: number,
	clientShotNonce: string,
	clientTimestamp: number,
}

export type ShotResult = {
	carryYards: number,
	rollYards: number,
	totalYards: number,
	lateralOffsetYards: number,
	finalPosition: Vector2Yards,
	finalSurface: Surface,
}

export type RoundStartPayload = {
	mode: string,
	courseId: string,
	teeSet: string,
	pinSet: string,
	ranked: boolean,
}

export type PartyMember = {
	userId: number,
	displayName: string,
	role: string,
	ready: boolean,
	teamId: string?,
}

export type PartyState = {
	partyId: string,
	code: string,
	leaderUserId: number,
	status: string,
	desiredMode: string,
	courseId: string,
	teeSet: string,
	pinSet: string,
	ranked: boolean,
	members: { PartyMember },
}

export type MatchInfo = {
	matchId: string,
	partyId: string,
	mode: string,
	courseId: string,
	transport: string,
	accessCode: string?,
	placeId: number?,
	playerUserIds: { number },
	teams: any?,
}

export type ScrambleBallOption = {
	ballId: string,
	playerUserId: number,
	teamId: string,
	position: Vector2Yards,
	surface: Surface,
	holed: boolean,
	penalty: boolean,
	distanceToPinYards: number,
}

export type ScrambleVoteState = {
	roundId: string,
	holeIndex: number,
	shotCycle: number,
	teamId: string,
	options: { ScrambleBallOption },
	votesByUserId: { [number]: string },
	selectedBallId: string?,
	expiresAtUnix: number,
}
return {}
