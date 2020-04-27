/**
 * Priority Queue.
 *  Peek and Pop always return the current lowest value in the list.
 *  Sort is done on insertion only.
 */
class Priority_Queue
{
	_queue = null;

	constructor()
	{
		_queue = [];
	}

	/**
	 * Insert a new entry in the list.
	 *  The complexity of this operation is O(n).
	 * @param item The item to add to the list.
	 * @param priority The priority this item has.
	 */
	function Insert(item, priority);

	/**
	 * Pop the first entry of the list.
	 *  This is always the item with the lowest priority.
	 *  The complexity of this operation is O(1).
	 * @return The item of the entry with the lowest priority.
	 */
	function Pop();

	/**
	 * Peek the first entry of the list.
	 *  This is always the item with the lowest priority.
	 *  The complexity of this operation is O(1).
	 * @return The item of the entry with the lowest priority.
	 */
	function Peek();

	/**
	 * Get the amount of current items in the list.
	 *  The complexity of this operation is O(1).
	 * @return The amount of items currently in the list.
	 */
	function Count();

	/**
	 * Check if an item exists in the list.
	 *  The complexity of this operation is O(n).
	 * @param item The item to check for.
	 * @return True if the item is already in the list.
	 */
	function Exists(item);
};

function Priority_Queue::Insert(item, priority)
{
	local L = 0;
	local R = --_queue.len();
	while (L <= R) {
		local m = (L + R) / 2;
		if (_queue[m][1] < priority) {
			R = --m;
		} else {
			L = ++m;
		}
	}
	_queue.insert(++R, [item, priority]);
//	return true;
}

function Priority_Queue::Pop()
{
	return /*!_queue.len() ? null : */_queue.pop()[0];
}

function Priority_Queue::Peek()
{
	return !_queue.len() ? null : _queue[--_queue.len()][0];
}

function Priority_Queue::Count()
{
	return _queue.len();
}

function Priority_Queue::Exists(item)
{
	/* Brute-force find the item (there is no faster way, as we don't have the priority number) */
	foreach (node in _queue) {
		if (node[0] == item) return true;
	}

	return false;
}
