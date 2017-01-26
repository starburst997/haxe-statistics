package;

import statistics.Stats;

// Tests
enum Tests
{
  Test1;
}

/**
 * Class used to Test statistics
 *
 * Install https://github.com/tapio/live-server and start from html5 folder
 * Simply issue "live-server" inside the html5 folder and build (release for faster build)
 * Server will reload page automatically when JS is compiled
 */
class TestStats
{
  // Stats
  public var stats:Stats;

  // Run some tests
  public function new()
  {
    trace("TestStats Launch");

    var test = Test1;

    switch(test)
    {
      case Test1: startTest1();
    }
  }

  // Simply load a URL and do nothing else
  function startTest1()
  {
    trace("Test 1");

    stats = new Stats();
  }
}