/**
 * Simply using AIList of indexes is faster than any squirrel implementation.
 *
 * Please note! It's not possible to check if an item exists in the list
 *  with this priority queue. Sorry!
 */
class Sorted_List
{
	_queue = null;
	_sorter = null;

	constructor()
	{
		_queue = [];
		_sorter = AIList();
		_sorter.Sort(AIList.SORT_BY_VALUE, AIList.SORT_ASCENDING);
	}

	/**
	 * Insert a new entry in the list.
	 *  The complexity of this operation is UNKNOWN
	 * @param item The item to add to the list.
	 * @param priority The priority this item has.
	 * @return True afterwards
	 */
	function Insert(item, priority);

	/**
	 * Pop the first entry of the list.
	 *  This is always the item with the lowest priority.
	 *  The complexity of this operation is UNKNOWN
	 * @return The item of the entry with the lowest priority.
	 */
	function Pop();

	/**
	 * Peek the first entry of the list.
	 *  This is always the item with the lowest priority.
	 *  The complexity of this operation is UNKNOWN
	 * @return The item of the entry with the lowest priority.
	 */
	function Peek();

	/**
	 * Get the amount of current items in the list.
	 *  The complexity of this operation is O(1)
	 * @return The amount of items currently in the list.
	 */
	function Count();

	/**
	 * It's not possible to check if an item exists in the list
	 *  with this priority queue. Sorry!
	 * @param item The item to check for.
	 */
	function Exists(item);
};

function Sorted_List::Insert(item, priority)
{
	_queue.push(item);
	_sorter.AddItem(--_queue.len(), priority);
//	return true;
}

function Sorted_List::Pop()
{
//	if (_sorter.IsEmpty()) return null;
	local ret = _queue[_sorter.Begin()];
	_sorter.RemoveTop(1);
	return ret;
}

function Sorted_List::Peek()
{
	return _sorter.IsEmpty() ? null : _queue[_sorter.Begin()];
}

function Sorted_List::Count()
{
	return _sorter.Count();
}

function Sorted_List::Exists(item)
{
	throw("It's not possible to check if an item exists in the list with this priority queue. Sorry!");
}
