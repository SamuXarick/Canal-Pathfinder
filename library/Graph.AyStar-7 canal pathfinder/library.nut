class AyStar extends AILibrary {
	function GetAuthor()      { return "SamuXarick"; }
	function GetName()        { return "AyStar"; }
	function GetShortName()   { return "GRA*"; }
	function GetDescription() { return "An implementation of AyStar"; }
	function GetVersion()     { return 7; }
	function GetDate()        { return "2020-04-12"; }
	function CreateInstance() { return "AyStar"; }
	function GetCategory()    { return "Graph"; }
}

RegisterLibrary(AyStar());
