--!strict

local LieModel = require("../../../ReplicatedStorage/Shared/GolfPro/Simulation/LieModel")

export type HoleScore = {
	holeIndex: number,
	par: number,
	strokes: number,
	penaltyStrokes: number,
	completed: boolean,
}

export type Scorecard = {
	holes: { [number]: HoleScore },
	totalStrokes: number,
	totalPenaltyStrokes: number,
	completed: boolean,
}

local ScoreService = {}

function ScoreService.createScorecard(course: any, holeCount: number?): Scorecard
	local count = holeCount or #course.holes
	local scorecard: Scorecard = {
		holes = {},
		totalStrokes = 0,
		totalPenaltyStrokes = 0,
		completed = false,
	}

	for index = 1, count do
		local hole = course.holes[index]
		scorecard.holes[index] = {
			holeIndex = index,
			par = hole.par,
			strokes = 0,
			penaltyStrokes = 0,
			completed = false,
		}
	end

	return scorecard
end

function ScoreService.recordShot(
	scorecard: Scorecard,
	holeIndex: number,
	finalSurface: string,
	holed: boolean
): HoleScore
	local holeScore = scorecard.holes[holeIndex]
	assert(holeScore ~= nil, "unknown scorecard hole")

	local lie = LieModel.get(finalSurface)
	local penaltyStrokes = lie.penaltyStrokes or 0
	holeScore.strokes += 1
	holeScore.penaltyStrokes += penaltyStrokes
	holeScore.completed = holeScore.completed or holed
	scorecard.totalStrokes += 1
	scorecard.totalPenaltyStrokes += penaltyStrokes

	return holeScore
end

function ScoreService.completeHole(scorecard: Scorecard, holeIndex: number)
	local holeScore = scorecard.holes[holeIndex]
	assert(holeScore ~= nil, "unknown scorecard hole")
	holeScore.completed = true

	for _, score in scorecard.holes do
		if not score.completed then
			scorecard.completed = false
			return
		end
	end

	scorecard.completed = true
end

function ScoreService.holeTotal(score: HoleScore): number
	return score.strokes + score.penaltyStrokes
end

function ScoreService.total(scorecard: Scorecard): number
	return scorecard.totalStrokes + scorecard.totalPenaltyStrokes
end

function ScoreService.snapshot(scorecard: Scorecard)
	local holes = {}
	for index, score in scorecard.holes do
		holes[index] = {
			holeIndex = score.holeIndex,
			par = score.par,
			strokes = score.strokes,
			penaltyStrokes = score.penaltyStrokes,
			total = ScoreService.holeTotal(score),
			completed = score.completed,
		}
	end

	return {
		holes = holes,
		totalStrokes = scorecard.totalStrokes,
		totalPenaltyStrokes = scorecard.totalPenaltyStrokes,
		total = ScoreService.total(scorecard),
		completed = scorecard.completed,
	}
end

return ScoreService
