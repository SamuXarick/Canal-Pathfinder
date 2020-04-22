/**
 * A Canal Pathfinder.
 */
class Canal
{
	_aystar_class = import("graph.aystar", "", 7);
	_max_cost = null;               ///< The maximum cost for a route.
	_cost_tile = null;              ///< The cost for walking a single tile.
	_cost_no_existing_water = null; ///< The cost that is added to _cost_tile if no water exists yet.
	_cost_diagonal_tile = null;     ///< The cost for walking a diagonal tile.
	_cost_turn45 = null;            ///< The cost that is added to _cost_tile if the direction changes 45 degrees.
	_cost_turn90 = null;            ///< The cost that is added to _cost_tile if the direction changes 90 degrees. 
	_cost_aqueduct_per_tile = null; ///< The cost per tile of a new aqueduct, this is added to _cost_tile.
	_cost_lock = null;              ///< The cost for a new lock, this is added to _cost_tile.
	_cost_depot = null;             ///< The cost for an existing depot, this is added to _cost_tile.
	_pathfinder = null;             ///< A reference to the used AyStar object.
	_max_aqueduct_length = null;    ///< The maximum length of an aqueduct that will be build.

	cost = null;                    ///< Used to change the costs.
	_running = null;
	_goals = null;

	constructor()
	{
		this._max_cost = 10000000;
		this._cost_tile = 100;
		this._cost_no_existing_water = 200;
		this._cost_diagonal_tile = 70;
		this._cost_turn45 = 100;
		this._cost_turn90 = 600;
		this._cost_aqueduct_per_tile = 400;
		this._cost_lock = 925;
		this._cost_depot = 150;
		this._max_aqueduct_length = 6;
		this._pathfinder = this._aystar_class(this, this._Cost, this._Estimate, this._Neighbours, this._CheckDirection);

		this.cost = this.Cost(this);
		this._running = false;
	}

	/**
	 * Initialize a path search between sources and goals.
	 * @param sources The source tiles.
	 * @param goals The target tiles.
	 * @param ignored_tiles An array of tiles that cannot occur in the final path.
	 * @see AyStar::InitializePath()
	 */
	function InitializePath(sources, goals, ignored_tiles = []) {
		local nsources = [];

		foreach (node in sources) {
			local path = this._pathfinder.Path(null, node[1], 0xFF, this._Cost, this);
			path = this._pathfinder.Path(path, node[0], 0xFF, this._Cost, this);
			nsources.push(path);
		}
		this._goals = goals;
		this._pathfinder.InitializePath(nsources, goals, ignored_tiles);
	}

	/**
	 * Try to find the path as indicated with InitializePath with the lowest cost.
	 * @param iterations After how many iterations it should abort for a moment.
	 *  This value should either be -1 for infinite, or > 0. Any other value
	 *  aborts immediately and will never find a path.
	 * @return A route if one was found, or false if the amount of iterations was
	 *  reached, or null if no path was found.
	 *  You can call this function over and over as long as it returns false,
	 *  which is an indication it is not yet done looking for a route.
	 * @see AyStar::FindPath()
	 */
	function FindPath(iterations);
};

class Canal.Cost
{
	_main = null;

	function _set(idx, val)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");

		switch (idx) {
			case "max_cost":            this._main._max_cost = val; break;
			case "tile":                this._main._cost_tile = val; break;
			case "no_existing_water":   this._main._cost_no_existing_water = val; break;
			case "diagonal_tile":       this._main._cost_diagonal_tile = val; break;
			case "turn45":              this._main._cost_turn45 = val; break;
			case "turn90":              this._main._cost_turn90 = val; break;
			case "aqueduct_per_tile":   this._main._cost_aqueduct_per_tile = val; break;
			case "lock":                this._main._cost_lock = val; break;
			case "depot":               this._main._cost_depot = val; break;
			case "max_aqueduct_length": this._main._max_aqueduct_length = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}

		return val;
	}

	function _get(idx)
	{
		switch (idx) {
			case "max_cost":            return this._main._max_cost;
			case "tile":                return this._main._cost_tile;
			case "no_existing_water":   return this._main._cost_no_existing_water;
			case "diagonal_tile":       return this._main._cost_diagonal_tile;
			case "turn45":              return this._main._cost_turn45;
			case "turn90":              return this._main._cost_turn90;
			case "aqueduct_per_tile":   return this._main._cost_aqueduct_per_tile;
			case "lock":                return this._main._cost_lock;
			case "depot":               return this._main._cost_depot;
			case "max_aqueduct_length": return this._main._max_aqueduct_length;
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main)
	{
		this._main = main;
	}
};

function Canal::FindPath(iterations)
{
	local test_mode = AITestMode();
	local ret = this._pathfinder.FindPath(iterations);
	this._running = (ret == false) ? true : false;
	if (!this._running && ret != null) {
		foreach (goal in this._goals) {
			if (goal[0] == ret.GetTile()) {
				return this._pathfinder.Path(ret, goal[1], 0, this._Cost, this);
			}
		}
	}
	return ret;
}

function Canal::_Cost(self, path, new_tile, new_direction)
{
	/* path == null means this is the first node of a path, so the cost is 0. */
	if (path == null) return 0;

	local prev_tile = path.GetTile();
//	AILog.Info("-Cost, prev_tile: " + prev_tile + " new_tile: " + new_tile);

	/* If the new tile is an aqueduct, check whether we came from the other
	 *  end of the aqueduct or if we just entered the aqueduct. */
	if (self._IsAqueductTile(new_tile)) {
		if (AIBridge.GetOtherBridgeEnd(new_tile) != prev_tile) {
			local cost = 0;
			if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
				cost = self._cost_diagonal_tile;
//				AILog.Info("Enter aqueduct. Cost for a diagonal tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
			} else {
				cost = self._cost_tile;
//				AILog.Info("Enter aqueduct. Cost for a tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
			}
			if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
//				AILog.Info("Enter aqueduct. Check for a 45 degrees turn, Before: " + (path.GetCost() + cost) + " After: " + (path.GetCost() + cost + self._cost_turn45));
				cost += self._cost_turn45;
			}
			return path.GetCost() + cost;
		}
//		AILog.Info("Cross aqueduct, Before: " + path.GetCost() + " After: " + (path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile));
		return path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile;
	}

	/* If the new tile is a lock, check whether we came from the other
	 *  end of the lock or if we just entered the lock. */
	if (self._IsLockEntryExit(new_tile)) {
		if (self._GetOtherLockEnd(new_tile) != prev_tile) {
			local cost = 0;
			if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
				cost = self._cost_diagonal_tile;
//				AILog.Info("Enter lock. Cost for a diagonal tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
			} else {
				cost = self._cost_tile;
//				AILog.Info("Enter lock. Cost for a tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
			}
			if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
//				AILog.Info("Enter lock. Check for a 45 degrees turn, Before: " + (path.GetCost() + cost) + " After: " + (path.GetCost() + cost + self._cost_turn45));
				cost += self._cost_turn45;
			}
			return path.GetCost() + cost;
		}
//		AILog.Info("Cross lock, Before: " + path.GetCost() + " After: " + (path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile));
		return path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile;
	}

	/* If the new tile is a depot, check whether we came from the other
	 *  end of the depot or if we just entered the depot. */
	if (AIMarine.IsWaterDepotTile(new_tile)) {
		if (self._GetOtherDepotTile(new_tile) != prev_tile) {
			local cost = 0;
			if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
				cost = self._cost_diagonal_tile;
//				AILog.Info("Enter depot. Cost for a diagonal tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
			} else {
				cost = self._cost_tile;
//				AILog.Info("Enter depot. Cost for a tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
			}
			if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
//				AILog.Info("Enter depot. Check for a 45 degrees turn, Before: " + (path.GetCost() + cost) + " After: " + (path.GetCost() + cost + self._cost_turn45));
				cost += self._cost_turn45;
			}
			return path.GetCost() + cost;
		}
//		AILog.Info("Cross depot, Before: " + path.GetCost() + " After: " + (path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile + self._cost_depot));
		return path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile + self._cost_depot;
	}

	/* If the two tiles are 1 tile apart and are sloped, or more than 1 tile apart, the pathfinder wants an aqueduct
	 *  to be build. It isn't an existing aqueduct, as that case is already handled. */
	if (AIMap.DistanceManhattan(new_tile, prev_tile) > 1 || AIMap.DistanceManhattan(new_tile, prev_tile) == 1 && self._CheckAqueductSlopes(prev_tile, new_tile)) {
		local cost = path.GetCost();
		/* If the tiles are exactly 2 tiles apart and both are flat, the pathfinder wants a lock
		 *  to be build. It isn't and existing lock, as that case is already handled. */
		if (AIMap.DistanceManhattan(new_tile, prev_tile) == 2 && self._IsFlatTile(new_tile) && self._IsFlatTile(prev_tile)) {
//			AILog.Info("Build lock. Cross lock, Before: " + cost + " After: " + (cost + 2 * self._cost_tile + self._cost_lock));
			cost += 2 * self._cost_tile + self._cost_lock;
		} else {
//			AILog.Info("Build aqueduct. Cross aqueduct, Before: " + cost + " After: " + (cost + AIMap.DistanceManhattan(new_tile, prev_tile) * (self._cost_tile + self._cost_aqueduct_per_tile) + self._cost_aqueduct_per_tile));
			cost += AIMap.DistanceManhattan(new_tile, prev_tile) * (self._cost_tile + self._cost_aqueduct_per_tile) + self._cost_aqueduct_per_tile;
		}
		if (path.GetParent() != null && path.GetParent().GetParent() != null) {
			local next_tile = new_tile - (new_tile - prev_tile) / AIMap.DistanceManhattan(new_tile, prev_tile);
			if (AIMap.DistanceManhattan(next_tile, path.GetParent().GetParent().GetTile()) == 3 &&
					path.GetParent().GetParent().GetTile() - path.GetParent().GetTile() != prev_tile - next_tile) {
//				AILog.Info("Build aqueduct or lock. Check for a 45 degrees turn, Before: " + cost + " After: " + (cost + self._cost_turn45));
				cost += self._cost_turn45;
			}
		}
		return cost;
	}

	/* Check for a turn. We do this by substracting the TileID of the current
	 *  node from the TileID of the previous node and comparing that to the
	 *  difference between the tile before the previous node and the node before
	 *  that. */
	local cost = 0;
	if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) {
		cost = self._cost_diagonal_tile;
//		AILog.Info("Cost for a diagonal tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
	} else {
		cost = self._cost_tile;
//		AILog.Info("Cost for a tile, Before: " + path.GetCost() + " After: " + (path.GetCost() + cost));
	}
	if (path.GetParent() != null && path.GetParent().GetParent() != null &&
			AIMap.DistanceManhattan(new_tile, path.GetParent().GetParent().GetTile()) == 3 &&
			path.GetParent().GetParent().GetTile() - path.GetParent().GetTile() != prev_tile - new_tile) {
//		AILog.Info("Check for a 45 degrees turn, Before: " + (path.GetCost() + cost) + " After: " + (path.GetCost() + cost + self._cost_turn45));
		cost += self._cost_turn45;
	}
	
	/* Chek for a 90 degrees turn */
	if (path.GetParent() != null && path.GetParent().GetParent() != null &&
			new_tile - prev_tile == path.GetParent().GetParent().GetTile() - path.GetParent().GetTile()) {
//		AILog.Info("Check for a 90 degrees turn, Before: " + (path.GetCost() + cost) + " After: " + (path.GetCost() + cost + self._cost_turn90));
		cost += self._cost_turn90;
	}

	/* Check for no existing water */
	if (path.GetParent() != null && !AIMarine.AreWaterTilesConnected(prev_tile, new_tile)) {
//		AILog.Info("Check for no existing water, Before: " + (path.GetCost() + cost) + " After: " + (path.GetCost() + cost + self._cost_no_existing_water));
		cost += self._cost_no_existing_water;
	}

	return path.GetCost() + cost;
}

function Canal::_Estimate(self, cur_tile, cur_direction, goal_tiles)
{
	local min_cost = self._max_cost;
	/* As estimate we multiply the lowest possible cost for a single tile with
	 *  with the minimum number of tiles we need to traverse. */
	foreach (tile in goal_tiles) {
		local dx = abs(AIMap.GetTileX(cur_tile) - AIMap.GetTileX(tile[0]));
		local dy = abs(AIMap.GetTileY(cur_tile) - AIMap.GetTileY(tile[0]));
		min_cost = min(min_cost, min(dx, dy) * self._cost_diagonal_tile * 2 + (max(dx, dy) - min(dx, dy)) * self._cost_tile);
	}
	return min_cost;
}

function Canal::_Neighbours(self, path, cur_node)
{
	/* self._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
	if (path.GetCost() >= self._max_cost) return [];
	local tiles = [];
	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
	                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];

	/* Check if the current tile is part of an aqueduct. */
	if (self._IsAqueductTile(cur_node)) {
		local other_end = AIBridge.GetOtherBridgeEnd(cur_node);
		local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		if (self._IsGoalTile(next_tile) || AIMarine.AreWaterTilesConnected(cur_node, next_tile) || AIMarine.BuildCanal(next_tile) || self._CanBuildAqueduct(cur_node, next_tile) || AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER) && (!AITile.IsWaterTile(next_tile) || AIMarine.IsCanalTile(next_tile) || self._IsLockEntryExit(next_tile) && self._CanConnectToLock(cur_node, next_tile) || AIMarine.IsWaterDepotTile(next_tile) && self._CanConnectToDepot(cur_node, next_tile))) {
			tiles.push([next_tile, self._GetDirection(null, cur_node, next_tile, false)]);
//			AILog.Info(cur_node + "; 1. Aqueduct detected, pushed next_tile = " + next_tile + "; parent_tile = " + path.GetParent().GetTile());
//			AIController.Sleep(74);
		}
		/* The other end of the aqueduct is a neighbour. */
		tiles.push([other_end, self._GetDirection(null, next_tile, cur_node, true)]);
//		AILog.Info(cur_node + "; 1. Aqueduct detected, pushed other_end = " + other_end + "; parent_tile = " + path.GetParent().GetTile());
//		AIController.Sleep(74);
	} else if (self._IsLockEntryExit(cur_node)) {
		local other_end = self._GetOtherLockEnd(cur_node);
		local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		if (self._IsGoalTile(next_tile) || AIMarine.AreWaterTilesConnected(cur_node, next_tile) || AIMarine.BuildCanal(next_tile) || self._CanBuildAqueduct(cur_node, next_tile) || AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER) && (!AITile.IsWaterTile(next_tile) || AIMarine.IsCanalTile(next_tile) || self._IsLockEntryExit(next_tile) && self._CanConnectToLock(cur_node, next_tile) || AIMarine.IsWaterDepotTile(next_tile) && self._CanConnectToDepot(cur_node, next_tile))) {
			tiles.push([next_tile, self._GetDirection(null, cur_node, next_tile, false)]);
//			AILog.Info(cur_node + "; 1. Lock detected, pushed next_tile = " + next_tile + "; parent_tile = " + path.GetParent().GetTile());
//			AIController.Sleep(74);
		}
		/* The other end of the lock is a neighbour. */
		tiles.push([other_end, self._GetDirection(null, next_tile, cur_node, true)]);
//		AILog.Info(cur_node + "; 1. Lock detected, pushed other_end = " + other_end + "; parent_tile = " + path.GetParent().GetTile());
//		AIController.Sleep(74);
	} else if (AIMarine.IsWaterDepotTile(cur_node)) {
		local other_end = self._GetOtherDepotTile(cur_node);
		local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		if (self._IsGoalTile(next_tile) || AIMarine.AreWaterTilesConnected(cur_node, next_tile) || AIMarine.BuildCanal(next_tile) || self._CanBuildAqueduct(cur_node, next_tile) || AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER) && (!AITile.IsWaterTile(next_tile) || AIMarine.IsCanalTile(next_tile) || self._IsLockEntryExit(next_tile) && self._CanConnectToLock(cur_node, next_tile) || AIMarine.IsWaterDepotTile(next_tile) && self._CanConnectToDepot(cur_node, next_tile))) {
			tiles.push([next_tile, self._GetDirection(null, cur_node, next_tile, false)]);
//			AILog.Info(cur_node + "; 1. Depot detected, pushed next_tile = " + next_tile + "; parent_tile = " + path.GetParent().GetTile());
//			AIController.Sleep(74);
		}
		/* The other end of the depot is a neighbour. */
		tiles.push([other_end, self._GetDirection(null, next_tile, cur_node, true)]);
//		AILog.Info(cur_node + "; 1. Depot detected, pushed other_end = " + other_end + "; parent_tile = " + path.GetParent().GetTile());
//		AIController.Sleep(74);
	} else if (path.GetParent() != null && AIMap.DistanceManhattan(cur_node, path.GetParent().GetTile()) == 2 && self._IsFlatTile(cur_node)) {
		local other_end = path.GetParent().GetTile();
		local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		if (self._IsGoalTile(next_tile) || AIMarine.AreWaterTilesConnected(cur_node, next_tile) || AIMarine.BuildCanal(next_tile) || self._CanBuildAqueduct(cur_node, next_tile) || AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER) && (!AITile.IsWaterTile(next_tile) || AIMarine.IsCanalTile(next_tile) || self._IsLockEntryExit(next_tile) && self._CanConnectToLock(cur_node, next_tile) || AIMarine.IsWaterDepotTile(next_tile) && self._CanConnectToDepot(cur_node, next_tile))) {
			tiles.push([next_tile, self._GetDirection(other_end, cur_node, next_tile, true)]);
//			AILog.Info(cur_node + "; 2. Lock detected, pushed next_tile = " + next_tile + "; parent_tile = " + path.GetParent().GetTile());
//			AIController.Sleep(74);
		}
	} else if (path.GetParent() != null && (AIMap.DistanceManhattan(cur_node, path.GetParent().GetTile()) > 1 || AIMap.DistanceManhattan(cur_node, path.GetParent().GetTile()) == 1 && self._CheckAqueductSlopes(path.GetParent().GetTile(), cur_node))) {
		local other_end = path.GetParent().GetTile();
		local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
		if (self._IsGoalTile(next_tile) || AIMarine.AreWaterTilesConnected(cur_node, next_tile) || AIMarine.BuildCanal(next_tile) || self._CanBuildAqueduct(cur_node, next_tile) || AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER) && (!AITile.IsWaterTile(next_tile) || AIMarine.IsCanalTile(next_tile) || self._IsLockEntryExit(next_tile) && self._CanConnectToLock(cur_node, next_tile) || AIMarine.IsWaterDepotTile(next_tile) && self._CanConnectToDepot(cur_node, next_tile))) {
			tiles.push([next_tile, self._GetDirection(other_end, cur_node, next_tile, true)]);
//			AILog.Info(cur_node + "; 2. Aqueduct detected, pushed next_tile = " + next_tile + "; parent_tile = " + path.GetParent().GetTile());
//			AIController.Sleep(74);
		}
	} else {
		/* Check all tiles adjacent to the current tile. */
		foreach (offset in offsets) {
			local next_tile = cur_node + offset;
			/* Don't turn back */
			if (path.GetParent() != null && next_tile == path.GetParent().GetTile()) continue;
//			/* Disallow 90 degree turns */
//			if (path.GetParent() != null && path.GetParent().GetParent() != null &&
//					next_tile - cur_node == path.GetParent().GetParent().GetTile() - path.GetParent().GetTile()) continue;
			/* We add them to the to the neighbours-list if one of the following applies:
			 * 1) There already is a connection between the current tile and the next tile.
			 * 2) We can build a canal to the next tile.
			 * 3) The next tile is the entrance of an aqueduct, depot or lock in the correct direction. */
			if ((path.GetParent() == null || AIMarine.AreWaterTilesConnected(path.GetParent().GetTile(), cur_node) || AIMarine.BuildCanal(cur_node) || AITile.HasTransportType(cur_node, AITile.TRANSPORT_WATER)) &&
					(self._IsGoalTile(next_tile) || AIMarine.AreWaterTilesConnected(cur_node, next_tile) && (!self._IsAqueductTile(next_tile) || self._CanConnectToAqueduct(cur_node, next_tile)) || AIMarine.BuildCanal(next_tile) || self._CanBuildAqueduct(cur_node, next_tile) || AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER) && (!AITile.IsWaterTile(next_tile) && !AITile.IsCoastTile(next_tile) && !self._IsAqueductTile(next_tile) || AIMarine.IsCanalTile(next_tile) || self._IsLockEntryExit(next_tile) && self._CanConnectToLock(cur_node, next_tile) || AIMarine.IsWaterDepotTile(next_tile) && self._CanConnectToDepot(cur_node, next_tile) || self._IsAqueductTile(next_tile) && self._CanConnectToAqueduct(cur_node, next_tile)))) {
				tiles.push([next_tile, self._GetDirection(path.GetParent() == null ? null : path.GetParent().GetTile(), cur_node, next_tile, false)]);
//				AILog.Info(cur_node + "; 3. Build Canal, pushed next_tile = " + next_tile + "; parent_tile = " + path.GetParent().GetTile());
//				AIController.Sleep(74);
			}
		}
		if (path.GetParent() != null) {
			local aqueduct = self._GetAqueduct(path.GetParent().GetTile(), cur_node, self._GetDirection(path.GetParent().GetParent() == null ? null : path.GetParent().GetParent().GetTile(), path.GetParent().GetTile(), cur_node, true));
			foreach (tile in aqueduct) {
				tiles.push(tile);
//				AILog.Info(cur_node + "; 4. Build Aqueduct, pushed tile = " + tile[0] + "; parent_tile = " + path.GetParent().GetTile());
//				AIController.Sleep(74);
			}
			foreach (offset in offsets) {
				local offset_tile = cur_node + offset;
				if (self._IsInclinedTile(offset_tile) && AIMarine.BuildLock(offset_tile) && self._CheckLockDirection(cur_node, offset_tile)) {
					local other_end = offset_tile + offset;
					local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
					if (next_tile == path.GetParent().GetTile() && !self._LockBlocksConnection(cur_node, offset_tile) &&
							(path.GetParent().GetParent() == null || AIMap.DistanceManhattan(path.GetParent().GetParent().GetTile(), next_tile) != 2 || self._IsFlatTile(next_tile) && !self._PreviousLockBlocksConnection(next_tile, cur_node))) {
						tiles.push([other_end, self._GetDirection(path.GetParent().GetParent() == null ? null : path.GetParent().GetParent().GetTile(), path.GetParent().GetTile(), cur_node, true)]);
//						AILog.Info(cur_node + "; 4. Build Lock, pushed other_end = " + other_end + "; parent_tile = " + path.GetParent().GetTile());
//						AIController.Sleep(74);
					}
				}
			}
		}
	}
	return tiles;
}

function Canal::_CheckDirection(self, tile, existing_direction, new_direction)
{
	return false;
}

function Canal::_dir(from, to)
{
	if (from - to == 1) return 0;
	if (from - to == -1) return 1;
	if (from - to == AIMap.GetMapSizeX()) return 2;
	if (from - to == -AIMap.GetMapSizeX()) return 3;
	throw("Shouldn't come here in _dir");
}

function Canal::_GetDirection(pre_from, from, to, is_aqueduct)
{
	if (is_aqueduct) {
		if (from - to == 1) return 1;
		if (from - to == -1) return 2;
		if (from - to == AIMap.GetMapSizeX()) return 4;
		if (from - to == -AIMap.GetMapSizeX()) return 8;
	}
	return 1 << (4 + (pre_from == null ? 0 : 4 * this._dir(pre_from, from)) + this._dir(from, to));
}

/**
 * Get the aqueduct that can be build from the
 *  current tile. Aqueducts are only build on sloped tiles.
 */
function Canal::_GetAqueduct(last_node, cur_node, aqueduct_dir)
{
	local tiles = [];
	if (!this._IsInclinedTile(cur_node)) return tiles;

	for (local i = 1; i < this._max_aqueduct_length; i++) {
		local target = cur_node + i * (cur_node - last_node);
		if (AIBridge.BuildBridge(AIVehicle.VT_WATER, 0, cur_node, target)) {
			tiles.push([target, aqueduct_dir]);
			break;
		}
	}

	return tiles;
}

function Canal::_CanBuildAqueduct(last_node, cur_node)
{
	if (!this._IsInclinedTile(cur_node)) return false;
	if (AIBridge.IsBridgeTile(cur_node)) return false;

	for (local i = 1; i < this._max_aqueduct_length; i++) {
		local target = cur_node + i * (cur_node - last_node);
		if (AIBridge.BuildBridge(AIVehicle.VT_WATER, 0, cur_node, target)) return true;
	}

	return false;
}

function Canal::_CanConnectToAqueduct(prev_tile, aqueduct_tile)
{
	assert(this._IsAqueductTile(aqueduct_tile));
	
	local slope = AITile.GetSlope(aqueduct_tile);
	local offset;
	if (slope == AITile.SLOPE_NE) {
		offset = AIMap.GetTileIndex(-1, 0);
	} else if (slope == AITile.SLOPE_SE) {
		offset = AIMap.GetTileIndex(0, 1);
	} else if (slope == AITile.SLOPE_NW) {
		offset = AIMap.GetTileIndex(0, -1);
	} else if (slope == AITile.SLOPE_SW) {
		offset = AIMap.GetTileIndex(1, 0);
	}
	
	return prev_tile == aqueduct_tile + offset;
}

/**
 * Special check for when determining the possibility of a 2 tile
 *  aqueduct crossing the same edge. Checks wether the slopes are
 *  suitable and in the correct direction for such aqueduct.
 */
function Canal::_CheckAqueductSlopes(tile_a, tile_b)
{
	local slope_a = AITile.GetSlope(tile_a);
	if (AIMap.DistanceManhattan(tile_a, tile_b) != 1) return false;
    if (!this._IsInclinedTile(tile_a) || !this._IsInclinedTile(tile_b)) return false;

	local slope_a = AITile.GetSlope(tile_a);
	if (AITile.GetComplementSlope(slope_a) != AITile.GetSlope(tile_b)) return false;

	local offset;
	if (slope_a == AITile.SLOPE_NE) {
		offset = AIMap.GetTileIndex(1, 0);
	} else if (slope_a == AITile.SLOPE_SE) {
		offset = AIMap.GetTileIndex(0, -1);
	} else if (slope_a == AITile.SLOPE_SW) {
		offset = AIMap.GetTileIndex(-1, 0);
	} else if (slope_a == AITile.SLOPE_NW) {
		offset = AIMap.GetTileIndex(0, 1);
	}

	return tile_a + offset == tile_b;
}

function Canal::_IsAqueductTile(tile)
{
	return AIBridge.IsBridgeTile(tile) && AITile.HasTransportType(tile, AITile.TRANSPORT_WATER);
}

function Canal::_GetOtherDepotChainEnd(tile)
{
	assert(AIMarine.IsWaterDepotTile(tile));

	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
	                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];

	local end_tile = tile;
	foreach (offset in offsets) {
		local next_tile = tile + offset;
		local cur_tile = tile;
		while (AIMarine.IsWaterDepotTile(next_tile) && AIMarine.AreWaterTilesConnected(cur_tile, next_tile)) {
			end_tile = next_tile;
			next_tile += offset;
			cur_tile += offset;
		}
	}

	return end_tile;
}

function Canal::_GetOtherDepotTile(tile)
{
	assert(AIMarine.IsWaterDepotTile(tile));

	local end1 = this._GetOtherDepotChainEnd(tile);
	local end2 = this._GetOtherDepotChainEnd(end1);

	if (end1 > end2) {
		local swap = end1;
		end1 = end2;
		end2 = swap;
	}

	local length = AIMap.DistanceManhattan(end1, end2) + 1;

	local offset = AIMap.GetTileIndex(1, 0);
	if (AIMap.GetTileX(end1) == AIMap.GetTileX(end2)) {
		offset = AIMap.GetTileIndex(0, 1);
	}

	local next_tile = end1 + offset;
	do {
		if (AIMarine.IsWaterDepotTile(next_tile) && AIMarine.AreWaterTilesConnected(end1, next_tile)) {
			if (end1 == tile) {
				return next_tile;
			} else if (next_tile == tile) {
				return end1;
			}
			end1 += 2 * offset;
			next_tile += 2 * offset;
			length -=2;
		}
	} while (length != 0);
}

function Canal::_CanConnectToDepot(prev_tile, depot_tile)
{
	assert(AIMarine.IsWaterDepotTile(depot_tile));

	local next_tile = depot_tile + (depot_tile - prev_tile);
	return AIMarine.IsWaterDepotTile(next_tile) && AIMarine.AreWaterTilesConnected(depot_tile, next_tile);
}

function Canal::_IsLockEntryExit(tile)
{
	return AIMarine.IsLockTile(tile) && this._IsFlatTile(tile);
}

function Canal::_GetLockMiddleTile(tile)
{
	assert(AIMarine.IsLockTile(tile));

	if (this._IsInclinedTile(tile)) return tile;

	assert(this._IsLockEntryExit(tile));

	local other_end = this._GetOtherLockEnd(tile);
	return tile - (tile - other_end) / 2;

}

function Canal::_GetOtherLockEnd(tile)
{
	assert(this._IsLockEntryExit(tile));

	local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
	                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];

	foreach (offset in offsets) {
		local middle_tile = tile + offset;
		if (AIMarine.IsLockTile(middle_tile) && this._IsInclinedTile(middle_tile)) {
			return middle_tile + offset;
		}
	}
}

function Canal::_CheckLockDirection(prev_tile, middle_tile)
{
	assert(this._IsInclinedTile(middle_tile));

	local slope = AITile.GetSlope(middle_tile);
	if (slope == AITile.SLOPE_SW || slope == AITile.SLOPE_NE) {
		return prev_tile == middle_tile + 1 || prev_tile == middle_tile - 1;
	} else if (slope == AITile.SLOPE_SE || slope == AITile.SLOPE_NW) {
		return prev_tile == middle_tile + AIMap.GetMapSizeX() || prev_tile == middle_tile - AIMap.GetMapSizeX();
	}

	return false;
}

function Canal::_LockBlocksConnection(prev_tile, middle_tile)
{
	assert(this._IsInclinedTile(middle_tile));
	
	local offset_mid;
	local offset_side;
	if (AIMap.GetTileY(prev_tile) != AIMap.GetTileY(middle_tile)) {
		offset_mid = AIMap.GetTileIndex(0, 1);
		offset_side = AIMap.GetTileIndex(1, 0);
	} else if (AIMap.GetTileX(prev_tile) != AIMap.GetTileX(middle_tile)) {
		offset_mid = AIMap.GetTileIndex(1, 0);
		offset_side = AIMap.GetTileIndex(0, 1);
	}
	
	/* m = middle, s = side, p = positive, n = negative, 2 = two times */
	local t_mp = middle_tile + offset_mid;
	local t_mn = middle_tile - offset_mid;
	local t_2mp = t_mp + offset_mid;
	local t_2mn = t_mn - offset_mid;
	local t_sp = middle_tile + offset_side;
	local t_sn = middle_tile - offset_side;
	local t_mp_sp = t_mp + offset_side;
	local t_mp_sn = t_mp - offset_side;
	local t_mn_sp = t_mn + offset_side;
	local t_mn_sn = t_mn - offset_side;
	local t_2mp_sp = t_2mp + offset_side;
	local t_2mp_sn = t_2mp - offset_side;
	local t_2mn_sp = t_2mn + offset_side;
	local t_2mn_sn = t_2mn - offset_side;
	
	if (this._IsAqueductTile(t_mp_sp)) return true;
	if (this._IsAqueductTile(t_mp_sn)) return true;
	if (this._IsAqueductTile(t_mn_sp)) return true;
	if (this._IsAqueductTile(t_mn_sn)) return true;
	
	if (this._IsWaterDockTile(t_mp_sp) && this._GetDockDockingTile(t_mp_sp) == t_mp) return true;
	if (this._IsWaterDockTile(t_mp_sn) && this._GetDockDockingTile(t_mp_sn) == t_mp) return true;
	if (this._IsWaterDockTile(t_mn_sp) && this._GetDockDockingTile(t_mn_sp) == t_mn) return true;
	if (this._IsWaterDockTile(t_mn_sn) && this._GetDockDockingTile(t_mn_sn) == t_mn) return true;

	if (AIMarine.AreWaterTilesConnected(t_mp, t_mp_sp)) {
		if (AIMarine.IsWaterDepotTile(t_mp_sp)) return true;
		if (this._IsLockEntryExit(t_mp_sp)) return true;
		if (this._IsOneCornerRaisedTile(t_mp_sp)) {
			if (AIMarine.AreWaterTilesConnected(t_mp_sp, t_sp)) return true;
		}
	}

	if (AIMarine.AreWaterTilesConnected(t_mp, t_mp_sn)) {
		if (AIMarine.IsWaterDepotTile(t_mp_sn)) return true;
		if (this._IsLockEntryExit(t_mp_sn)) return true;
		if (this._IsOneCornerRaisedTile(t_mp_sn)) {
			if (AIMarine.AreWaterTilesConnected(t_mp_sn, t_sn)) return true;
		}
	}	

	if (AIMarine.AreWaterTilesConnected(t_mn, t_mn_sp)) {
		if (AIMarine.IsWaterDepotTile(t_mn_sp)) return true;
		if (this._IsLockEntryExit(t_mn_sp)) return true;
		if (this._IsOneCornerRaisedTile(t_mn_sp)) {
			if (AIMarine.AreWaterTilesConnected(t_mn_sp, t_sp)) return true;
		}
	}	

	if (AIMarine.AreWaterTilesConnected(t_mn, t_mn_sn)) {
		if (AIMarine.IsWaterDepotTile(t_mn_sn)) return true;
		if (this._IsLockEntryExit(t_mn_sn)) return true;
		if (this._IsOneCornerRaisedTile(t_mn_sn)) {
			if (AIMarine.AreWaterTilesConnected(t_mn_sn, t_sn)) return true;
		}
	}

	if (AIMarine.AreWaterTilesConnected(t_mp, t_2mp)) {
		if (AIMarine.AreWaterTilesConnected(t_mp, t_mp_sp)) {
			if (!AIMarine.AreWaterTilesConnected(t_2mp_sp, t_mp_sp) || !AIMarine.AreWaterTilesConnected(t_2mp_sp, t_2mp)) return true;
		}
		if (AIMarine.AreWaterTilesConnected(t_mp, t_mp_sn)) {
			if (!AIMarine.AreWaterTilesConnected(t_2mp_sn, t_mp_sn) || !AIMarine.AreWaterTilesConnected(t_2mp_sn, t_2mp)) return true;
		}
	}

	if (AIMarine.AreWaterTilesConnected(t_mn, t_2mn)) {
		if (AIMarine.AreWaterTilesConnected(t_mn, t_mn_sp)) {
			if (!AIMarine.AreWaterTilesConnected(t_2mn_sp, t_mn_sp) || !AIMarine.AreWaterTilesConnected(t_2mn_sp, t_2mn)) return true;
		}
		if (AIMarine.AreWaterTilesConnected(t_mn, t_mn_sn)) {
			if (!AIMarine.AreWaterTilesConnected(t_2mn_sn, t_mn_sn) || !AIMarine.AreWaterTilesConnected(t_2mn_sn, t_2mn)) return true;
		}
	}
	
	if (AIMarine.AreWaterTilesConnected(t_mp, t_mp_sp) && AIMarine.AreWaterTilesConnected(t_mp, t_mp_sn)) {
		if (!AIMarine.AreWaterTilesConnected(t_mp, t_2mp)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mp, t_2mp_sp)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mp, t_2mp_sn)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mp_sp, t_mp_sp)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mp_sn, t_mp_sn)) {
			return true;
		}
	}
	
	if (AIMarine.AreWaterTilesConnected(t_mn, t_mn_sp) && AIMarine.AreWaterTilesConnected(t_mn, t_mn_sn)) {
		if (!AIMarine.AreWaterTilesConnected(t_mn, t_2mn)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mn, t_2mn_sp)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mn, t_2mn_sn)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mn_sp, t_mn_sp)) {
			return true;
		} else if (!AIMarine.AreWaterTilesConnected(t_2mn_sn, t_mn_sn)) {
			return true;
		}
	}
	
	return false;
}

function Canal::_PreviousLockBlocksConnection(prev_lock, new_lock)
{
	local offset;
	if (AIMap.GetTileY(prev_lock) != AIMap.GetTileY(new_lock)) {
		offset = AIMap.GetTileIndex(1, 0);
	} else if (AIMap.GetTileX(prev_lock) != AIMap.GetTileX(new_lock)) {
		offset = AIMap.GetTileIndex(0, 1);
	}

	local offset_tile1 = prev_lock + offset;
	local offset_tile2 = prev_lock - offset;
	local offset_tile3 = new_lock + offset;
	local offset_tile4 = new_lock - offset;
	if ((AIMarine.IsLockTile(prev_lock) || 
			(AIMarine.AreWaterTilesConnected(prev_lock, offset_tile1) || this._IsWaterDockTile(offset_tile1) && this._GetDockDockingTile(offset_tile1) == prev_lock) &&
			(AIMarine.AreWaterTilesConnected(prev_lock, offset_tile2) || this._IsWaterDockTile(offset_tile2) && this._GetDockDockingTile(offset_tile2) == prev_lock)) &&
			(AIMarine.AreWaterTilesConnected(new_lock, offset_tile3) || this._IsWaterDockTile(offset_tile3) && this._GetDockDockingTile(offset_tile3) == new_lock) &&
			(AIMarine.AreWaterTilesConnected(new_lock, offset_tile4) || this._IsWaterDockTile(offset_tile4) && this._GetDockDockingTile(offset_tile4) == new_lock)) {
		return true;
	}
	
	return false;
}

function Canal::_CanConnectToLock(prev_tile, lock_tile)
{
	assert(this._IsLockEntryExit(lock_tile));

	local middle_tile = this._GetLockMiddleTile(lock_tile);
	local slope = AITile.GetSlope(middle_tile);
	if (slope == AITile.SLOPE_SW || slope == AITile.SLOPE_NE) {
		return AIMap.GetTileX(prev_tile) != AIMap.GetTileX(lock_tile);
	} else if (slope == AITile.SLOPE_SE || slope == AITile.SLOPE_NW) {
		return AIMap.GetTileY(prev_tile) != AIMap.GetTileY(lock_tile);
	}

	return false;
}

function Canal::_IsWaterDockTile(tile)
{
	return AIMarine.IsDockTile(tile) && this._IsFlatTile(tile);
}

function Canal::_GetDockDockingTile(dock_tile)
{
	assert(AIMarine.IsDockTile(dock_tile));

	local dock_slope;
	if (this._IsWaterDockTile(dock_tile)) {
		local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1), AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
		foreach (offset in offsets) {
			local offset_tile = dock_tile + offset;
			if (AIMarine.IsDockTile(offset_tile) && this._IsInclinedTile(offset_tile)) {
				dock_slope = offset_tile;
				break;
			}
		}
	} else {
		dock_slope = dock_tile;
	}
	
	local slope = AITile.GetSlope(dock_slope);
	if (slope == AITile.SLOPE_NE) {
		return dock_slope + AIMap.GetTileIndex(2, 0);
	} else if (slope == AITile.SLOPE_SE) {
		return dock_slope + AIMap.GetTileIndex(0, -2);
	} else if (slope == AITile.SLOPE_SW) {
		return dock_slope + AIMap.GetTileIndex(-2, 0);
	} else if (slope == AITile.SLOPE_NW) {
		return dock_slope + AIMap.GetTileIndex(0, 2);
	}
}

function Canal::_IsGoalTile(tile)
{
	foreach (goal in this._goals) {
		if (goal[1] == tile) {
			return true;
		}
	}

	return false;
}

function Canal::_IsInclinedTile(tile)
{
	local slope = AITile.GetSlope(tile);
	return slope == AITile.SLOPE_SW || slope == AITile.SLOPE_NW || slope == AITile.SLOPE_SE || slope == AITile.SLOPE_NE;
}

function Canal::_IsFlatTile(tile)
{
	return AITile.GetSlope(tile) == AITile.SLOPE_FLAT;
}

function Canal::_IsOneCornerRaisedTile(tile)
{
	local slope = AITile.GetSlope(tile);
	return slope == AITile.SLOPE_N || slope == AITile.SLOPE_S || slope == AITile.SLOPE_E || slope == AITile.SLOPE_W;
}
