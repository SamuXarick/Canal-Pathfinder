class Priority_Queue extends AILibrary {
	function GetAuthor()      { return "OpenTTD NoAI Developers Team + RailwAI + SamuXarick"; }
	function GetName()        { return "Priority Queue"; }
	function GetShortName()   { return "QUPQ"; }
	function GetDescription() { return "An implementation of a Priority Queue"; }
	function GetVersion()     { return 4; }
	function GetDate()        { return "2020-04-21"; }
	function CreateInstance() { return "Priority_Queue"; }
	function GetCategory()    { return "Queue"; }
}

RegisterLibrary(Priority_Queue());
