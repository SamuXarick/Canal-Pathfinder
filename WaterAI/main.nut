import("pathfinder.canal", "CanalPathFinder", 1);

class WaterAI extends AIController
{
	static offsets = [AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(-1, 0), AIMap.GetTileIndex(0, -1)];

	function Start()
	{
		local build_depots = false;
		local remove_docks = false;
		local connection = 0;
//		while (true)
		{
/*
			build_depots = true;
			remove_docks = true
			connection++;
			local name_a = connection.tostring() + "A";
			local name_b = connection.tostring() + "B";
			local dock_a = BuildDocks(name_a);
			local dock_b = BuildDocks(name_b);
			local built_a = dock_a[1];
			local built_b = dock_b[1];
//			local built_a = dock_a[2];
//			local built_b = dock_b[2];
			AILog.Info("water_tile1 = " + dock_a[0]);
			AILog.Info("water_tile2 = " + dock_b[0]);
//			AILog.Info("water_tile1 = " + dock_a[0] + "; water_tile1_exit = " + dock_a[1]);
//			AILog.Info("water_tile2 = " + dock_b[0] + "; water_tile2_exit = " + dock_a[1]);
*/
			local pathfinder = CanalPathFinder();
			pathfinder.cost.max_aqueduct_length = AIGameSettings().GetValue("max_bridge_length") + 2;
//			pathfinder.InitializePath([dock_a[0]], [dock_b[0]]);
//			pathfinder.InitializePath([[dock_a[0], dock_a[1]]], [[dock_b[0], dock_b[1]]]);
//			pathfinder.InitializePath([1380], [2596]);
//			pathfinder.InitializePath([46575], [9786], [46831, 10042]);
//			pathfinder.InitializePath([AIMap.GetTileIndex(216, 214)], [AIMap.GetTileIndex(87, 195)], [AIMap.GetTileIndex(216, 213), AIMap.GetTileIndex(86, 195)]);
//			pathfinder.InitializePath([AIMap.GetTileIndex(176, 89)], [AIMap.GetTileIndex(134, 77)], [AIMap.GetTileIndex(134, 78), AIMap.GetTileIndex(177, 89)]);
//			pathfinder.InitializePath([[AIMap.GetTileIndex(176, 89), AIMap.GetTileIndex(177, 89)]], [[AIMap.GetTileIndex(134, 77), AIMap.GetTileIndex(134, 78)]]);
			pathfinder.InitializePath([AIMap.GetTileIndex(108, 144)], [AIMap.GetTileIndex(170, 59)], [AIMap.GetTileIndex(109, 144), AIMap.GetTileIndex(170, 58)]);
//			pathfinder.InitializePath([[AIMap.GetTileIndex(108, 144), AIMap.GetTileIndex(109, 144)]], [[AIMap.GetTileIndex(170, 59), AIMap.GetTileIndex(170, 58)]]);
			local tick = AIController.GetTick();
			local date = AIDate.GetCurrentDate();
			local path = pathfinder.FindPath(-1);
			AILog.Info(path);

//			AIController.Break("Pathfinding took " + (AIController.GetTick() - tick) + " ticks / " + (AIDate.GetCurrentDate() - date) + " days");
			AILog.Warning("Pathfinding took " + (AIController.GetTick() - tick) + " ticks / " + (AIDate.GetCurrentDate() - date) + " days");

			if (path == null && remove_docks) {
				foreach (tile in built_a) {
					if (AICompany.IsMine(AITile.GetOwner(tile))) {
						if (AIMarine.IsDockTile(tile) && AITile.GetSlope(tile) == AITile.SLOPE_FLAT) AITile.DemolishTile(tile);
						AITile.DemolishTile(tile);
					}
				}
				foreach (tile in built_b) {
					if (AICompany.IsMine(AITile.GetOwner(tile))) {
						if (AIMarine.IsDockTile(tile) && AITile.GetSlope(tile) == AITile.SLOPE_FLAT) AITile.DemolishTile(tile);
						AITile.DemolishTile(tile);
					}
				}
			} else {
				local paths = [path];
				for (local i = 0; i < paths.len(); i++) {
					path = paths[i];
					local tile_list = BuildPath(path, connection);
//					local tile_list = BuildPathOld(path, connection);
					AIController.Break("Path built!");
					local built_depot = false;
					if (build_depots) {
						for (local tile = tile_list.Begin(); !tile_list.IsEnd(); tile = tile_list.Next()) {
							local top_tile = tile;
							local bot_tile = tile_list.GetValue(tile);
							if (top_tile > bot_tile) {
								local swap = top_tile;
								top_tile = bot_tile;
								bot_tile = swap;
							}
							if (!BuildingDepotBlocksConnection(top_tile, bot_tile) && AIMarine.BuildWaterDepot(top_tile, bot_tile)) {
								built_depot = true;
								AILog.Info("Built depot at " + top_tile);
								AISign.BuildSign(top_tile, (connection.tostring() + "D"));
								AISign.BuildSign(bot_tile, (connection.tostring() + "D"));
								break;
							}
						}
//						if (!built_depot) AIController.Break("Failed to build depot");
					}
				}
			}

			local signs_list = AISignList();
			for (local sign = signs_list.Begin(); !signs_list.IsEnd(); sign = signs_list.Next()) {
				AISign.RemoveSign(sign);
			}
		}
	}

	function IsRiverTile(tile)
	{
		if (!AITile.IsWaterTile(tile)) return false;
		if (AITile.GetMaxHeight(tile) == 0) return false;
		if (AIMarine.IsWaterDepotTile(tile)) return false;
		if (AIMarine.IsCanalTile(tile)) return false;
		if (AIMarine.IsLockTile(tile)) return false;
		return true;
	}

	function IsSeaTile(tile)
	{
		if (!AITile.IsWaterTile(tile)) return false;
		if (AITile.GetMaxHeight(tile) > 0) return false;
		if (AIMarine.IsWaterDepotTile(tile)) return false;
		if (AIMarine.IsCanalTile(tile)) return false;
		if (AIMarine.IsLockTile(tile)) return false;
		return true;
	}

	function BuildDocks(connection)
	{
		local water_tile1_exit = AIMap.TILE_INVALID;
		local water_tile1 = AIMap.TILE_INVALID;
		local water_tile1_next = AIMap.TILE_INVALID;

		local built = [];
		local success = false;
		do {
			water_tile1_exit = AIMap.TILE_INVALID;
			water_tile1 = AIMap.TILE_INVALID;
			water_tile1_next = AIMap.TILE_INVALID;
			do {
				water_tile1_exit = AIBase.RandRange(AIMap.GetMapSize());
			} while (!(AITile.GetSlope(water_tile1_exit) == AITile.SLOPE_FLAT && (AITile.IsBuildable(water_tile1_exit) || AITile.IsWaterTile(water_tile1_exit) && !AIMarine.IsWaterDepotTile(water_tile1_exit) && !AIMarine.IsLockTile(water_tile1_exit))));

			foreach (offset in offsets) {
				water_tile1_next = water_tile1_exit + offset;
				if (AIMap.IsValidTile(water_tile1_next) && CanalPathFinder()._IsInclinedTile(water_tile1_next) && AITile.IsBuildable(water_tile1_next)) {
					local slope = AITile.GetSlope(water_tile1_next);
					local offset2 = (slope == AITile.SLOPE_NE || slope == AITile.SLOPE_SW) ? AIMap.GetTileIndex(0, 1) : AIMap.GetTileIndex(1, 0);
					if (slope == AITile.SLOPE_NE && offset == AIMap.GetTileIndex(-1, 0) ||
							slope == AITile.SLOPE_SE && offset == AIMap.GetTileIndex(0, 1) ||
							slope == AITile.SLOPE_SW && offset == AIMap.GetTileIndex(1, 0) ||
							slope == AITile.SLOPE_NW && offset == AIMap.GetTileIndex(0, -1)) {
						water_tile1 = water_tile1_exit - offset;
					}
					if (AIMap.IsValidTile(water_tile1) && AITile.GetSlope(water_tile1) == AITile.SLOPE_FLAT && (AITile.IsBuildable(water_tile1) || AITile.IsWaterTile(water_tile1) && !AIMarine.IsWaterDepotTile(water_tile1) && !AIMarine.IsLockTile(water_tile1))) {
						local offsets2_pass = true;
						local tile_offset1 = water_tile1_exit + offset2;
						local tile_offset2 = water_tile1_exit - offset2;
						local tile_offset1_1 = water_tile1 + offset2;
						local tile_offset2_2 = water_tile1 - offset2;
						if (!AITile.IsWaterTile(water_tile1_exit)) {
							if (AIMarine.BuildCanal(water_tile1_exit)) {
								built.push(water_tile1_exit);
							}
						}
						if (!AITile.IsWaterTile(water_tile1)) {
							if (AIMarine.BuildCanal(water_tile1)) {
								built.push(water_tile1);
							}
						}

						if (CanalPathFinder()._IsLockEntryExit(tile_offset1) && CanalPathFinder()._CheckLockDirection(tile_offset1, CanalPathFinder()._GetLockMiddleTile(tile_offset1)) ||
								CanalPathFinder()._IsLockEntryExit(tile_offset2) && CanalPathFinder()._CheckLockDirection(tile_offset2, CanalPathFinder()._GetLockMiddleTile(tile_offset2))) {
							continue;
						}

						if (AIMarine.IsDockTile(tile_offset1) && CanalPathFinder()._GetDockDockingTile(tile_offset1) == water_tile1_exit ||
								AIMarine.IsDockTile(tile_offset2) && CanalPathFinder()._GetDockDockingTile(tile_offset2) == water_tile1_exit) {
							continue;
						}

						if (AIMarine.AreWaterTilesConnected(water_tile1_exit, tile_offset1) && AIMarine.AreWaterTilesConnected(water_tile1_exit, water_tile1)) {
							if (!(AIMarine.AreWaterTilesConnected(tile_offset1_1, tile_offset1) && AIMarine.AreWaterTilesConnected(tile_offset1_1, water_tile1))) {
								continue;
							}
						}
						if (AIMarine.AreWaterTilesConnected(water_tile1_exit, tile_offset2) && AIMarine.AreWaterTilesConnected(water_tile1_exit, water_tile1)) {
							if (!(AIMarine.AreWaterTilesConnected(tile_offset2_2, tile_offset2) && AIMarine.AreWaterTilesConnected(tile_offset2_2 water_tile1))) {
								continue;
							}
						}

						if (AIMarine.BuildDock(water_tile1_next, AIStation.STATION_NEW)) {
							built.push(water_tile1_next)
							AIBaseStation.SetName(AIStation.GetStationID(water_tile1_next), connection);
							success = true;
							break;
						}
					}
				}
			}
			if (!success) {
				foreach (tile in built) {
					if (AICompany.IsMine(AITile.GetOwner(tile))) {
						if (AIMarine.IsDockTile(tile) && AITile.GetSlope(tile) == AITile.SLOPE_FLAT) AITile.DemolishTile(tile);
						AITile.DemolishTile(tile);
					}
				}
				built = [];
			}
		} while (!success);

//		return [water_tile1, built];
		return [water_tile1, water_tile1_exit, built]
	}

	function BuildingDepotBlocksConnection(top_tile, bot_tile)
	{
		assert(AIMap.DistanceManhattan(top_tile, bot_tile) == 1);

		local offset = AIMap.GetTileX(top_tile) == AIMap.GetTileX(bot_tile) ? AIMap.GetTileIndex(1, 0) : AIMap.GetTileIndex(0, 1);

		local top_exit = top_tile + (top_tile - bot_tile);
		local bot_exit = bot_tile + (bot_tile - top_tile);
		local t_sp = top_tile + offset;
		local t_sn = top_tile - offset;
		local b_sp = bot_tile + offset;
		local b_sn = bot_tile - offset;
		local te_sp = top_exit + offset;
		local te_sn = top_exit - offset;
		local be_sp = bot_exit + offset;
		local be_sn = bot_exit - offset;

		local top_tile_top_exit = AIMarine.AreWaterTilesConnected(top_tile, top_exit);
		local bot_tile_bot_exit = AIMarine.AreWaterTilesConnected(bot_tile, bot_exit);
		local top_tile_t_sp = AIMarine.AreWaterTilesConnected(top_tile, t_sp);
		local top_tile_t_sn = AIMarine.AreWaterTilesConnected(top_tile, t_sn);
		local bot_tile_b_sp = AIMarine.AreWaterTilesConnected(bot_tile, b_sp);
		local bot_tile_b_sn = AIMarine.AreWaterTilesConnected(bot_tile, b_sn);
		local top_exit_te_sp = AIMarine.AreWaterTilesConnected(top_exit, te_sp);
		local top_exit_te_sn = AIMarine.AreWaterTilesConnected(top_exit, te_sn);
		local bot_exit_be_sp = AIMarine.AreWaterTilesConnected(bot_exit, be_sp);
		local bot_exit_be_sn = AIMarine.AreWaterTilesConnected(bot_exit, be_sn);
		local te_sp_t_sp = AIMarine.AreWaterTilesConnected(te_sp, t_sp);
		local te_sn_t_sn = AIMarine.AreWaterTilesConnected(te_sn, t_sn);
		local be_sp_b_sp = AIMarine.AreWaterTilesConnected(be_sp, b_sp);
		local be_sn_b_sn = AIMarine.AreWaterTilesConnected(be_sn, b_sn);
		local t_sp_b_sp = AIMarine.AreWaterTilesConnected(t_sp, b_sp);
		local t_sn_b_sn = AIMarine.AreWaterTilesConnected(t_sn, b_sn);

		if (!te_sn_t_sn && top_exit_te_sn && top_tile_top_exit && top_tile_t_sn) {
			if (!be_sn_b_sn || !bot_exit_be_sn) return true;
		}
		if (!top_exit_te_sn && top_tile_top_exit && top_tile_t_sn) {
			if (!t_sn_b_sn || !be_sn_b_sn || !bot_exit_be_sn) return true;
		}
		if (!top_exit_te_sp && top_tile_top_exit && top_tile_t_sp) {
			if (!t_sp_b_sp || !be_sp_b_sp || !bot_exit_be_sp) return true;
		}
		if (!te_sp_t_sp && top_exit_te_sp && top_tile_top_exit && top_tile_t_sp) {
			if (!be_sp_b_sp || !bot_exit_be_sp) return true;
		}

		if (!be_sn_b_sn && bot_exit_be_sn && bot_tile_bot_exit && bot_tile_b_sn) {
			if (!te_sn_t_sn || !top_exit_te_sn) return true;
		}
		if (!bot_exit_be_sn && bot_tile_bot_exit && bot_tile_b_sn) {
			if (!t_sn_b_sn || !te_sn_t_sn || !top_exit_te_sn) return true;
		}
		if (!bot_exit_be_sp && bot_tile_bot_exit && bot_tile_b_sp) {
			if (!t_sp_b_sp || !te_sp_t_sp || !top_exit_te_sp) return true;
		}

		if (!be_sp_b_sp && bot_exit_be_sp && bot_tile_bot_exit && bot_tile_b_sp) {
			if (!te_sp_t_sp || !top_exit_te_sp) return true;
		}

		if (!top_tile_top_exit) {
			if (top_tile_t_sp) {
				if (bot_tile_b_sp && !t_sp_b_sp) return true;
				if (bot_tile_bot_exit && (!t_sp_b_sp || !be_sp_b_sp || !bot_exit_be_sp)) return true;
				if (bot_tile_b_sn && (!t_sp_b_sp || !be_sp_b_sp || !bot_exit_be_sp || !bot_exit_be_sn || !be_sn_b_sn)) return true;
			}
			if (top_tile_t_sn) {
				if (bot_tile_b_sn && !t_sn_b_sn) return true;
				if (bot_tile_bot_exit && (!t_sn_b_sn || !be_sn_b_sn || !bot_exit_be_sn)) return true;
				if (bot_tile_b_sp && (!t_sn_b_sn || !be_sn_b_sn || !bot_exit_be_sn || !bot_exit_be_sp || !be_sp_b_sp)) return true;
			}
			if (bot_tile_b_sp) {
				if (!be_sp_b_sp || !bot_exit_be_sp || !bot_tile_bot_exit) return true;
			}
			if (bot_tile_b_sn) {
				if (!be_sn_b_sn || !bot_exit_be_sn || !bot_tile_bot_exit) return true;
			}
		}

		if (!bot_tile_bot_exit) {
			if (bot_tile_b_sp) {
				if (top_tile_t_sp && !t_sp_b_sp) return true;
				if (top_tile_top_exit && (!t_sp_b_sp || !te_sp_t_sp || !top_exit_te_sp)) return true;
				if (top_tile_t_sn && (!t_sp_b_sp || !te_sp_t_sp || !top_exit_te_sp || !top_exit_te_sn || !te_sn_t_sn)) return true;
			}
			if (bot_tile_b_sn) {
				if (top_tile_t_sn && !t_sn_b_sn) return true;
				if (top_tile_top_exit && (!t_sn_b_sn || !te_sn_t_sn || !top_exit_te_sn)) return true;
				if (top_tile_t_sp && (!t_sn_b_sn || !te_sn_t_sn || !top_exit_te_sn || !top_exit_te_sp || !te_sp_t_sp)) return true;
			}
			if (top_tile_t_sp) {
				if (!te_sp_t_sp || !top_exit_te_sp || !top_tile_top_exit) return true;
			}
			if (top_tile_t_sn) {
				if (!te_sn_t_sn || !top_exit_te_sn || !top_tile_top_exit) return true;
			}
		}

		if (CanalPathFinder()._IsAqueductTile(t_sp) || CanalPathFinder()._IsAqueductTile(t_sn) || CanalPathFinder()._IsAqueductTile(b_sp) || CanalPathFinder()._IsAqueductTile(b_sn)) return true;

		if (CanalPathFinder()._IsWaterDockTile(t_sp) && CanalPathFinder()._GetDockDockingTile(t_sp) == top_tile) return true;
		if (CanalPathFinder()._IsWaterDockTile(t_sn) && CanalPathFinder()._GetDockDockingTile(t_sn) == top_tile) return true;
		if (CanalPathFinder()._IsWaterDockTile(b_sp) && CanalPathFinder()._GetDockDockingTile(b_sp) == bot_tile) return true;
		if (CanalPathFinder()._IsWaterDockTile(b_sn) && CanalPathFinder()._GetDockDockingTile(b_sn) == bot_tile) return true;

		if (top_tile_t_sp) {
			if (AIMarine.IsWaterDepotTile(t_sp)) return true;
			if (CanalPathFinder()._IsLockEntryExit(t_sp)) return true;
			if (CanalPathFinder()._IsOneCornerRaisedTile(t_sp)) {
				if (t_sp_b_sp) return true;
			}
		}

		if (top_tile_t_sn) {
			if (AIMarine.IsWaterDepotTile(t_sn)) return true;
			if (CanalPathFinder()._IsLockEntryExit(t_sn)) return true;
			if (CanalPathFinder()._IsOneCornerRaisedTile(t_sn)) {
				if (t_sn_b_sn) return true;
			}
		}

		if (bot_tile_b_sp) {
			if (AIMarine.IsWaterDepotTile(b_sp)) return true;
			if (CanalPathFinder()._IsLockEntryExit(b_sp)) return true;
			if (CanalPathFinder()._IsOneCornerRaisedTile(b_sp)) {
				if (t_sp_b_sp) return true;
			}
		}

		if (bot_tile_b_sn) {
			if (AIMarine.IsWaterDepotTile(b_sn)) return true;
			if (CanalPathFinder()._IsLockEntryExit(b_sn)) return true;
			if (CanalPathFinder()._IsOneCornerRaisedTile(b_sn)) {
				if (t_sn_b_sn) return true;
			}
		}

		if (top_tile_top_exit) {
			if (top_tile_t_sp) {
				if (!te_sp_t_sp || !top_exit_te_sp) return true;
			}
			if (top_tile_t_sn) {
				if (!te_sn_t_sn || !top_exit_te_sn) return true;
			}
		}

		if (bot_tile_bot_exit) {
			if (bot_tile_b_sp) {
				if (!be_sp_b_sp || !bot_exit_be_sp) return true;
			}
			if (bot_tile_b_sn) {
				if (!be_sn_b_sn || !bot_exit_be_sn) return true;
			}
		}

		if (top_tile_t_sp && top_tile_t_sn) {
			if (!top_tile_top_exit) {
				return true;
			} else if (!top_exit_te_sp) {
				return true;
			} else if (!top_exit_te_sn) {
				return true;
			} else if (!te_sp_t_sp) {
				return true;
			} else if (!te_sn_t_sn) {
				return true;
			}
		}

		if (bot_tile_b_sp && bot_tile_b_sn) {
			if (!bot_tile_bot_exit) {
				return true;
			} else if (!bot_exit_be_sp) {
				return true;
			} else if (!bot_exit_be_sn) {
				return true;
			} else if (!be_sp_b_sp) {
				return true;
			} else if (!be_sn_b_sn) {
				return true;
			}
		}

		return false;
	}

	function BuildPathOld(path, connection)
	{
		local tile_list = AIList();

		local prev = null;
		local prevprev = null;
		while (path != null) {
			if (prevprev != null) {
				if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1 || CanalPathFinder()._CheckAqueductSlopes(prev, path.GetTile())) {
					if (AIMap.DistanceManhattan(prev, path.GetTile()) == 2 && AITile.GetSlope(prev) == AITile.SLOPE_FLAT && AITile.GetSlope(path.GetTile()) == AITile.SLOPE_FLAT) {
						local next_tile = prev - (prev - path.GetTile()) / 2;
						AISign.BuildSign(next_tile, connection.tostring());
						if (!AITile.HasTransportType(prev, AITile.TRANSPORT_WATER)) {
							if (/*AITestMode() && */AIMarine.BuildLock(next_tile)) {
//								AILog.Info("Built lock at " + next_tile);
							} else {
//								AILog.Warning("Failed lock at " + next_tile);
							}
						}
					} else {
						AISign.BuildSign(prev, connection.tostring());
						AISign.BuildSign(path.GetTile(), connection.tostring());
						if (!AITile.HasTransportType(prev, AITile.TRANSPORT_WATER)) {
							if (/*AITestMode() && */AIBridge.BuildBridge(AIVehicle.VT_WATER, 0, prev, path.GetTile())) {
//								AILog.Info("Built aqueduct at " + prev + " and " + path.GetTile());
							} else {
//								AILog.Warning("Failed aqueduct at " + prev + " and " + path.GetTile());
							}
						}
					}
					prevprev = prev;
					prev = path.GetTile();
					path = path.GetParent();
				} else {
					if (!AITile.HasTransportType(prev, AITile.TRANSPORT_WATER)) {
						AISign.BuildSign(prev, connection.tostring());
						if (/*AITestMode() && */AIMarine.BuildCanal(prev)) {
//							AILog.Info("Built canal at " + prev);
						} else {
//							AILog.Warning("Failed canal at " + prev);
						}
					}
					tile_list.AddItem(prev, path.GetTile());
				}
			}
			if (path != null) {
				prevprev = prev;
				prev = path.GetTile();
				path = path.GetParent();
			}
		}
		AILog.Warning("Placed " + connection + " signs");

		return tile_list;
	}


	function BuildPath(path, connection)
	{
		local tile_list = AIList();

		local last_node = null;
		while (path != null) {
			local par = path.GetParent();
			if (par != null) {
				if (AIMap.DistanceManhattan(par.GetTile(), path.GetTile()) > 1 || CanalPathFinder()._CheckAqueductSlopes(par.GetTile(), path.GetTile())) {
					if (AIMap.DistanceManhattan(par.GetTile(), path.GetTile()) == 2 && AITile.GetSlope(par.GetTile()) == AITile.SLOPE_FLAT && AITile.GetSlope(path.GetTile()) == AITile.SLOPE_FLAT) {
						local next_tile = par.GetTile() - (par.GetTile() - path.GetTile()) / 2;
//						if (!AITile.HasTransportType(next_tile, AITile.TRANSPORT_WATER)) {
							AISign.BuildSign(next_tile, connection.tostring());
							if (/*AITestMode() && */AIMarine.BuildLock(next_tile)) {
//								AILog.Info("Built lock at " + next_tile);
							} else {
//								AILog.Warning("Failed lock at " + next_tile);
							}
//						}
					} else {
//						if (!AITile.HasTransportType(par.GetTile(), AITile.TRANSPORT_WATER)) {
							AISign.BuildSign(par.GetTile(), connection.tostring());
							AISign.BuildSign(path.GetTile(), connection.tostring());
							if (/*AITestMode() && */AIBridge.BuildBridge(AIVehicle.VT_WATER, 0, par.GetTile(), path.GetTile())) {
//								AILog.Info("Built aqueduct at " + par.GetTile() + " and " + path.GetTile());
							} else {
//								AILog.Warning("Failed aqueduct at " + par.GetTile() + " and " + path.GetTile());
							}
//						}
					}
				} else {
//					if (!AITile.HasTransportType(par.GetTile(), AITile.TRANSPORT_WATER)) {
						AISign.BuildSign(par.GetTile(), connection.tostring());
						if (/*AITestMode() && */AIMarine.BuildCanal(par.GetTile())) {
//							AILog.Info("Built canal at " + par.GetTile());
						} else {
//							AILog.Warning("Failed canal at " + par.GetTile());
						}
//					}
//					if (!AITile.HasTransportType(path.GetTile(), AITile.TRANSPORT_WATER)) {
						AISign.BuildSign(path.GetTile(), connection.tostring());
						if (/*AITestMode() && */AIMarine.BuildCanal(path.GetTile())) {
//							AILog.Info("Built canal at " + path.GetTile());
						} else {
//							AILog.Warning("Failed canal at " + path.GetTile());
						}
//					}
					tile_list.AddItem(par.GetTile(), path.GetTile());
				}
			}
			last_node = path.GetTile();
			path = par;
		}
		AILog.Warning("Placed " + connection + " signs");

		return tile_list;
	}
}
