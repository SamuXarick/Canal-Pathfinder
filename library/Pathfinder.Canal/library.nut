class Canal extends AILibrary {
	function GetAuthor()      { return "SamuXarick"; }
	function GetName()        { return "Canal"; }
	function GetShortName()   { return "PFCL"; }
	function GetDescription() { return "An implementation of a canal pathfinder"; }
	function GetVersion()     { return 2; }
	function GetDate()        { return "2021-07-18"; }
	function CreateInstance() { return "Canal"; }
	function GetCategory()    { return "Pathfinder"; }
	function GetAPIVersion()  { return "1.11"; }
}

RegisterLibrary(Canal());
