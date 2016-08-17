Battleship
==========

Write your own Battleship AI in Elixir and pit it against other players!

This idea (and much of this README) were taken from
https://github.com/threedaymonk/battleship

The game
--------

Long version: [see wikipedia](https://secure.wikimedia.org/wikipedia/en/wiki/Battleship_game)

* Each player starts with a fleet of 5 ships, of length 5, 4, 3, 3, and 2.
* Each player places their ships horizontally or vertically on a 10x10 grid;
  this is not visible to their opponent.
* Players take turns to fire at positions on the grid, gradually revealing
  where their opponent’s ships are and are not located.
* A ship is destroyed when every cell of a ship has been hit.
* The winner is the first player to destroy their opponent’s fleet.

You lose if:

* You do not place the correct number and size of ships.
* You place your fleet in impossible positions (ships overlapping or partly off the board).
* Your code raises an exception or crashes.
* All your ships have been sunk.

### Additional rules

* The player will not have access to the game objects.
* The player may use the provided `Grid` module as an implementation aid.
* The judge’s decision is final.

Implementation
--------------

Play takes place on a 10x10 grid. Co-ordinates are given in the order _(x,y)_
and are zero-indexed relative to the top left, i.e. _(0,0)_ is the top left,
_(9,0)_ is the top right, and _(9,9)_ is the bottom right.

A player is an Elixir process, which could be implemented as a GenServer or
Agent, or simply using `spawn` if desired.
It must implement handlers for the following messages.


### `name`

This must return a string containing the name of the team or player.

### `new_game`

This is called whenever a game starts. It must return the initial positioning
of the fleet as an list of five tuples, one for each ship. The format of each
tuple is:

    {x, y, length, orientation}

where `x` and `y` are the top left cell of the ship, length is its length
(2-5), and orientation is either `:across` or `:down`.

> NOTE: If your player implementation maintains any game-related state it is
> important to reinitialize the state for each `new_game` call!

### `take_turn(tracking_board, ships_remaining)`

`tracking_board` is a representation of the known state of the opponent’s fleet,
as modified by the player’s shots. It is given as a list of lists; the inner
lists represent horizontal rows. Each cell may be in one of three states:
`:unknown`, `:hit`, or `:miss`. E.g.

    [[:hit, :miss, :unknown, ...], [:unknown, :unknown, :unknown, ...], ...]
    # 0,0   1,0    2,0              0,1       1,1       2,1

`ships_remaining` is a list of the ships remaining on the opponent's board,
given as a list of numbers representing their lengths, longest first.
For example, the first two calls will always be:

    [5, 4, 3, 3, 2]

If the player is lucky enough to take out the length 2 ship on their first two
turns, the third turn will be called with:

    [5, 4, 3, 3]

and so on.

`take_turn` must return a tuple of co-ordinates for the next shot. In the
example above, we can see that the player has already played `{0,0}`, yielding
a hit, and `{1,0}`, giving a miss. They can now return a reasonable guess of
`{0,1}` for their next shot.

The console runner
------------------

A console runner is provided. It can be started using:

    mix run players/example/linear.exs players/example/random.exs

Yielding a game like the following:

![Example Game](http://assets.joingrouper.com/fight_club/battleship.gif)

A couple of very basic players are supplied: `StupidPlayer` puts all its ships
in a corner and guesses at random (often wasting turns by repeating itself).
`HumanPlayer` asks for input via the console.


## Getting Started

First make sure you have an up-to-date version of Elixir installed. Then you
can fork and clone this repository to set up your own Battleship development
enviroment. Make sure that everything is set up correctly by playing a sample
game between the two provided example players:

    mix deps.get
    mix deps.compile
    mix run bin/play_game.exs players/example/linear.exs players/example/random.exs

Assuming that everything worked correctly you can now begin working on your own
player implementation. You can copy one of the example player files to serve as
a starting point, but make sure you change both the module name and the string
returned from the `name` message handler so that it matches your player name.
You can test your player implementation against one of the example players as
follows:

    mix run players/example/linear.exs players/cincinnati-elixir/my_player.exs

(Where my_player.exs is the file that contains your player implementation.)
