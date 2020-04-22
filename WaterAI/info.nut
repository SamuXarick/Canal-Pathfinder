class WaterAI extends AIInfo {
	function GetAuthor()        { return "SamuXarick"; }
	function GetName()          { return "WaterAI"; }
	function GetDescription()   { return "Tests water pathfinder"; }
	function GetVersion()       { return 1; }
	function GetDate()          { return "07-04-2020"; }
	function CreateInstance()   { return "WaterAI"; }
	function GetShortName()     { return "WATR"; }
	function GetAPIVersion()    { return "1.10"; }
}

RegisterAI(WaterAI());
