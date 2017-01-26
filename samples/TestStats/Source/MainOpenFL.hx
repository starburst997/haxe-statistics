package;

import openfl.display.Sprite;

/**
 * Test statistics in OpenFL
 */
class MainOpenFL extends Sprite
{
  var test:TestStats;

  // Run some tests
	public function new()
  {
		super();

    // Test
		test = new TestStats();
	}
}