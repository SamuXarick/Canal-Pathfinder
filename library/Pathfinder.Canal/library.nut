class Canal extends AILibrary {
	function GetAuthor()      { return "SamuXarick"; }
	function GetName()        { return "Canal"; }
	function GetShortName()   { return "PFCL"; }
	function GetDescription() { return "An implementation of a canal pathfinder"; }
	function GetVersion()     { return 1; }
	function GetDate()        { return "2020-04-12"; }
	function CreateInstance() { return "Canal"; }
	function GetCategory()    { return "Pathfinder"; }
}

RegisterLibrary(Canal());
